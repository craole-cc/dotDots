#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! miette = { version = "7", features = ["fancy"] }
//! thiserror = "2"
//! ```

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use {
  clap::Parser,
  miette::{Diagnostic, IntoDiagnostic, Result},
  std::{
    env,
    ffi::OsString,
    path::{Path, PathBuf},
    process::{Command, Stdio},
  },
  thiserror::Error,
};

#[derive(Debug, Parser)]
#[command(
  name = "gcp",
  about = "Stage all changes, commit, and push.",
  disable_help_subcommand = true
)]
struct Cli {
  /// Commit without pushing.
  #[arg(long = "no-push")]
  no_push: bool,

  /// Explicit commit message.
  #[arg(long = "message", short = 'm')]
  message: Option<String>,

  /// Commit message. If omitted, the last commit subject is reused.
  #[arg(trailing_var_arg = true)]
  words: Vec<String>,
}

#[derive(Debug, Error, Diagnostic)]
enum GcpError {
  #[error("required command not found: {0}")]
  #[diagnostic(help(
    "Ensure the command exists on PATH, or inject it through the matching CMD_* variable."
  ))]
  RequiredCommandNotFound(String),

  #[error("git command failed: {0}")]
  GitFailed(String),
}

fn is_executable(path: &Path) -> bool {
  if !path.is_file() {
    return false;
  }

  #[cfg(unix)]
  {
    std::fs::metadata(path)
      .map(|meta| meta.permissions().mode() & 0o111 != 0)
      .unwrap_or(false)
  }

  #[cfg(not(unix))]
  {
    true
  }
}

fn find_cmd(name: &str) -> Option<PathBuf> {
  let candidate = Path::new(name);

  if name.contains('/') && is_executable(candidate) {
    return Some(candidate.to_path_buf());
  }

  let path_var: OsString = env::var_os("PATH")?;

  for dir in env::split_paths(&path_var) {
    let path = dir.join(name);

    if is_executable(&path) {
      return Some(path);
    }
  }

  None
}

fn env_or_find(env_name: &str, command: &str) -> Option<PathBuf> {
  env::var_os(env_name)
    .filter(|value| !value.is_empty())
    .map(PathBuf::from)
    .or_else(|| find_cmd(command))
}

fn require_cmd(env_name: &str, command: &str) -> Result<PathBuf> {
  env_or_find(env_name, command)
    .ok_or_else(|| GcpError::RequiredCommandNotFound(command.to_string()))
    .map_err(Into::into)
}

fn run_status(program: &Path, args: &[&str]) -> Result<bool> {
  let status = Command::new(program)
    .args(args)
    .status()
    .into_diagnostic()?;

  Ok(status.success())
}

fn output(program: &Path, args: &[&str]) -> Result<String> {
  let output = Command::new(program)
    .args(args)
    .stderr(Stdio::null())
    .output()
    .into_diagnostic()?;

  Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn main() -> Result<()> {
  let cli = Cli::parse();
  let git = require_cmd("CMD_GIT", "git")?;

  if !run_status(&git, &["add", "--all"])? {
    return Err(GcpError::GitFailed("git add --all".to_string()).into());
  }

  let status = output(&git, &["status", "--porcelain"])?;

  if status.trim().is_empty() {
    return Ok(());
  }

  let message = match cli.message {
    | Some(message) => message,
    | None if !cli.words.is_empty() => cli.words.join(" "),
    | None => output(&git, &["log", "-1", "--pretty=%B"])?
      .lines()
      .next()
      .unwrap_or("update")
      .to_string(),
  };

  if !run_status(&git, &["commit", "--message", &message])? {
    return Err(GcpError::GitFailed("git commit".to_string()).into());
  }

  if !cli.no_push && !run_status(&git, &["push"])? {
    return Err(GcpError::GitFailed("git push".to_string()).into());
  }

  Ok(())
}
