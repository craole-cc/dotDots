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
    name = "update",
    about = "Update flake, optional Rust dependencies, optional mise, commit changes, push, and \
           reload direnv.",
    disable_help_subcommand = true
)]
struct Cli {
    /// Also run cargo update.
    #[arg(long = "rust", alias = "cargo")]
    cargo: bool,

    /// Also run mise self-update.
    #[arg(long = "mise")]
    mise: bool,

    /// Skip nix flake update.
    #[arg(long = "no-flake")]
    no_flake: bool,
}

#[derive(Debug, Error, Diagnostic)]
enum UpdateError {
    #[error("command failed: {0}")]
    CommandFailed(String),
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

fn run(program: &Path, args: &[&str]) -> Result<bool> {
    let status = Command::new(program)
        .args(args)
        .status()
        .into_diagnostic()?;

    Ok(status.success())
}

fn run_quiet(program: &Path, args: &[&str]) -> Result<bool> {
    let status = Command::new(program)
        .args(args)
        .stderr(Stdio::null())
        .status()
        .into_diagnostic()?;

    Ok(status.success())
}

fn output(program: &Path, args: &[&str]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .output()
        .into_diagnostic()?;

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn maybe_run(program: Option<&PathBuf>, args: &[&str]) -> Result<()> {
    if let Some(program) = program {
        run(program, args)?;
    }

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let cargo = env_or_find("CMD_CARGO", "cargo");
    let direnv = env_or_find("CMD_DIRENV", "direnv");
    let git = env_or_find("CMD_GIT", "git");
    let mise = env_or_find("CMD_MISE", "mise");
    let nix = env_or_find("CMD_NIX", "nix");

    if !cli.no_flake {
        if let Some(nix) = &nix {
            run_quiet(nix, &["flake", "update"])?;
        }
    }

    if cli.cargo {
        if let Some(cargo) = &cargo {
            run(cargo, &["update"])?;
            run(cargo, &["reload"])?;
        }
    }

    if cli.mise {
        if let Some(mise) = &mise {
            run(mise, &["self-update"])?;
        }
    }

    if let Some(git) = &git {
        run(git, &["add", "--all"])?;

        let status = output(git, &["status", "--porcelain"])?;

        if !status.trim().is_empty() {
            if !run(git, &["commit", "--message", "update"])? {
                return Err(UpdateError::CommandFailed("git commit".to_string()).into());
            }

            if !run(git, &["push"])? {
                return Err(UpdateError::CommandFailed("git push".to_string()).into());
            }
        }
    }

    maybe_run(direnv.as_ref(), &["reload"])?;

    Ok(())
}
