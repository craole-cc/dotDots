#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! miette = { version = "7", features = ["fancy"] }
//! tempfile = "3"
//! thiserror = "2"
//! walkdir = "2"
//! ```

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use {
    clap::Parser,
    miette::{Diagnostic, IntoDiagnostic, Result},
    std::{
        env,
        ffi::OsString,
        fs,
        path::{Path, PathBuf},
        process::{Command, Stdio},
    },
    tempfile::NamedTempFile,
    thiserror::Error,
    walkdir::WalkDir,
};

#[derive(Debug, Parser)]
#[command(
    name = "fmt-rust",
    about = "Format .rs files under the project root or given paths.",
    disable_help_subcommand = true
)]
struct Cli {
    /// Check formatting without modifying files.
    #[arg(short = 'x', long = "check")]
    check: bool,

    /// Suppress all output except errors.
    #[arg(short = 'q', long = "quiet")]
    quiet: bool,

    /// Show formatter and discovery details.
    #[arg(short = 'V', long = "verbose")]
    verbose: bool,

    /// Verbose mode plus formatter-level verbosity.
    #[arg(short = 'd', long = "debug")]
    debug: bool,

    /// One or more .rs files or directories to format.
    #[arg()]
    paths: Vec<PathBuf>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Verbosity {
    Quiet,
    Normal,
    Verbose,
}

#[derive(Debug)]
struct Config {
    check: bool,
    debug: bool,
    verbosity: Verbosity,
    paths: Vec<PathBuf>,
}

#[derive(Debug, Error, Diagnostic)]
enum FmtError {
    #[error("neither leptosfmt nor rustfmt found")]
    #[diagnostic(help(
        "Install leptosfmt or rustfmt, or ensure one of them is available on PATH."
    ))]
    NoFormatter,

    #[error("not a file or directory: {0}")]
    NotFileOrDirectory(String),

    #[error("failed to find current directory")]
    CurrentDirectory,

    #[error("command failed: {0}")]
    CommandFailed(String),
}

impl From<Cli> for Config {
    fn from(cli: Cli) -> Self {
        let verbosity = if cli.quiet {
            Verbosity::Quiet
        } else if cli.verbose || cli.debug {
            Verbosity::Verbose
        } else {
            Verbosity::Normal
        };

        Self {
            check: cli.check,
            debug: cli.debug,
            verbosity,
            paths: cli.paths,
        }
    }
}

fn pass(config: &Config, message: impl AsRef<str>) {
    if config.verbosity != Verbosity::Quiet {
        eprintln!("fmt-rust: ✔ {}", message.as_ref());
    }
}

fn fail(message: impl AsRef<str>) {
    eprintln!("fmt-rust: ✗ {}", message.as_ref());
}

fn info(config: &Config, message: impl AsRef<str>) {
    if config.verbosity == Verbosity::Verbose {
        eprintln!("fmt-rust: {}", message.as_ref());
    }
}

fn is_executable(path: &Path) -> bool {
    if !path.is_file() {
        return false;
    }

    #[cfg(unix)]
    {
        fs::metadata(path)
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

fn command_output(program: &Path, args: &[&str]) -> Result<Option<String>> {
    let output = Command::new(program)
        .args(args)
        .output()
        .into_diagnostic()?;

    if !output.status.success() {
        return Ok(None);
    }

    Ok(Some(String::from_utf8_lossy(&output.stdout).to_string()))
}

fn find_root() -> Result<PathBuf> {
    if let Some(git) = find_cmd("git") {
        if let Some(output) = command_output(&git, &["rev-parse", "--show-toplevel"])? {
            let root = output.trim();

            if !root.is_empty() {
                return Ok(PathBuf::from(root));
            }
        }
    }

    env::current_dir()
        .map_err(|_| FmtError::CurrentDirectory)
        .map_err(Into::into)
}

fn discover_with_fd(root: &Path) -> Result<Option<Vec<PathBuf>>> {
    let Some(fd) = find_cmd("fd") else {
        return Ok(None);
    };

    let output = Command::new(fd)
        .args([
            "--type",
            "file",
            "--extension",
            "rs",
            "--exclude",
            "archives",
            ".",
        ])
        .arg(root)
        .output()
        .into_diagnostic()?;

    if !output.status.success() {
        return Ok(None);
    }

    let files = String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter(|line| !line.trim().is_empty())
        .map(PathBuf::from)
        .collect();

    Ok(Some(files))
}

fn discover_with_git(root: &Path) -> Result<Option<Vec<PathBuf>>> {
    let Some(git) = find_cmd("git") else {
        return Ok(None);
    };

    if !root.join(".git").is_dir() {
        return Ok(None);
    }

    let output = Command::new(git)
        .arg("-C")
        .arg(root)
        .args([
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "--",
            ":!*/.*",
            ":!archives/*",
            "*.rs",
        ])
        .output()
        .into_diagnostic()?;

    if !output.status.success() {
        return Ok(None);
    }

    let files = String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter(|line| !line.trim().is_empty())
        .map(|line| root.join(line))
        .collect();

    Ok(Some(files))
}

fn is_hidden_component(path: &Path) -> bool {
    path.components().any(|component| {
        component
            .as_os_str()
            .to_str()
            .is_some_and(|name| name.starts_with('.') && name != ".")
    })
}

fn discover_with_walkdir(root: &Path) -> Vec<PathBuf> {
    WalkDir::new(root)
        .into_iter()
        .filter_entry(|entry| {
            let path = entry.path();

            if path == root {
                return true;
            }

            let Some(name) = path.file_name().and_then(|name| name.to_str()) else {
                return true;
            };

            !(name == ".git" || name == "target" || name == "archives" || name.starts_with('.'))
        })
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.into_path())
        .filter(|path| {
            path.is_file()
                && path.extension().and_then(|ext| ext.to_str()) == Some("rs")
                && !is_hidden_component(path)
        })
        .collect()
}

fn discover_files(root: &Path) -> Result<Vec<PathBuf>> {
    if let Some(files) = discover_with_fd(root)? {
        return Ok(files);
    }

    if let Some(files) = discover_with_git(root)? {
        return Ok(files);
    }

    Ok(discover_with_walkdir(root))
}

fn collect_files_from_input(path: &Path, config: &Config) -> Result<Vec<PathBuf>> {
    if path.is_file() {
        return Ok(vec![path.to_path_buf()]);
    }

    if path.is_dir() {
        info(config, format!("scanning {}", path.display()));
        return discover_files(path);
    }

    Err(FmtError::NotFileOrDirectory(path.display().to_string()).into())
}

fn run_status(program: &Path, args: &[&str]) -> Result<bool> {
    let status = Command::new(program)
        .args(args)
        .status()
        .into_diagnostic()?;

    Ok(status.success())
}

fn run_capture_stderr(
    program: &Path,
    args: &[&str],
    input: Option<&[u8]>,
) -> Result<(bool, Vec<u8>, Vec<u8>)> {
    let mut command = Command::new(program);
    command.args(args);

    if input.is_some() {
        command.stdin(Stdio::piped());
    }

    command.stdout(Stdio::piped());
    command.stderr(Stdio::piped());

    let mut child = command.spawn().into_diagnostic()?;

    if let Some(input) = input {
        if let Some(stdin) = child.stdin.as_mut() {
            use std::io::Write;
            stdin.write_all(input).into_diagnostic()?;
        }
    }

    let output = child.wait_with_output().into_diagnostic()?;

    Ok((output.status.success(), output.stdout, output.stderr))
}

fn replay_stderr(stderr: &[u8]) {
    if !stderr.is_empty() {
        eprint!("{}", String::from_utf8_lossy(stderr));
    }
}

fn fmt_with_leptosfmt(
    file: &Path,
    leptosfmt: &Path,
    rustfmt: Option<&PathBuf>,
    config: &Config,
) -> Result<bool> {
    if config.debug {
        if config.check {
            let leptos_ok = run_status(
                leptosfmt,
                &[
                    "--experimental-tailwind",
                    "--check",
                    file.to_string_lossy().as_ref(),
                ],
            )?;

            let rust_ok = if let Some(rustfmt) = rustfmt {
                run_status(
                    rustfmt,
                    &["--check", "--verbose", file.to_string_lossy().as_ref()],
                )?
            } else {
                true
            };

            return Ok(leptos_ok && rust_ok);
        }

        let leptos_ok = run_status(
            leptosfmt,
            &["--experimental-tailwind", file.to_string_lossy().as_ref()],
        )?;

        let rust_ok = if let Some(rustfmt) = rustfmt {
            run_status(rustfmt, &["--verbose", file.to_string_lossy().as_ref()])?
        } else {
            true
        };

        return Ok(leptos_ok && rust_ok);
    }

    let content = fs::read(file).into_diagnostic()?;

    if config.check {
        let (ok, _stdout, stderr) = run_capture_stderr(
            leptosfmt,
            &[
                "--stdin",
                "--rustfmt",
                "--experimental-tailwind",
                "--quiet",
                "--check",
            ],
            Some(&content),
        )?;

        if !ok {
            replay_stderr(&stderr);
        }

        return Ok(ok);
    }

    let (ok, stdout, stderr) = run_capture_stderr(
        leptosfmt,
        &["--stdin", "--rustfmt", "--experimental-tailwind", "--quiet"],
        Some(&content),
    )?;

    if ok {
        let temp = NamedTempFile::new_in(file.parent().unwrap_or_else(|| Path::new(".")))
            .into_diagnostic()?;

        fs::write(temp.path(), stdout).into_diagnostic()?;
        temp.persist(file).into_diagnostic()?;
    } else {
        replay_stderr(&stderr);
    }

    Ok(ok)
}

fn fmt_with_rustfmt(file: &Path, rustfmt: &Path, config: &Config) -> Result<bool> {
    if config.debug {
        if config.check {
            return run_status(
                rustfmt,
                &["--check", "--verbose", file.to_string_lossy().as_ref()],
            );
        }

        return run_status(rustfmt, &["--verbose", file.to_string_lossy().as_ref()]);
    }

    let args = if config.check {
        vec!["--check", file.to_string_lossy().to_string()]
    } else {
        vec![file.to_string_lossy().to_string()]
    };

    let arg_refs = args.iter().map(String::as_str).collect::<Vec<_>>();

    let (ok, _stdout, stderr) = run_capture_stderr(rustfmt, &arg_refs, None)?;

    if !ok {
        replay_stderr(&stderr);
    }

    Ok(ok)
}

fn fmt_file(file: &Path, config: &Config) -> Result<bool> {
    let leptosfmt = find_cmd("leptosfmt");
    let rustfmt = find_cmd("rustfmt");

    if let Some(leptosfmt) = leptosfmt {
        info(config, format!("leptosfmt+rustfmt: {}", file.display()));
        return fmt_with_leptosfmt(file, &leptosfmt, rustfmt.as_ref(), config);
    }

    if let Some(rustfmt) = rustfmt {
        info(config, format!("rustfmt: {}", file.display()));
        return fmt_with_rustfmt(file, &rustfmt, config);
    }

    Err(FmtError::NoFormatter.into())
}

fn run(config: &Config) -> Result<i32> {
    let mut failed = false;

    let files = if config.paths.is_empty() {
        let root = find_root()?;
        info(config, format!("scanning {}", root.display()));
        discover_files(&root)?
    } else {
        let mut files = Vec::new();

        for path in &config.paths {
            files.extend(collect_files_from_input(path, config)?);
        }

        files
    };

    if files.is_empty() {
        info(config, "no .rs files found");
        return Ok(0);
    }

    for file in files {
        match fmt_file(&file, config) {
            Ok(true) => pass(config, file.display().to_string()),
            Ok(false) => {
                fail(file.display().to_string());
                failed = true;
            }
            Err(error) => {
                eprintln!("{error:?}");
                failed = true;
            }
        }
    }

    Ok(if failed { 1 } else { 0 })
}

fn main() -> Result<()> {
    let config = Config::from(Cli::parse());
    let status = run(&config)?;

    std::process::exit(status);
}
