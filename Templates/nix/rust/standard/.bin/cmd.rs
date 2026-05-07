#!/usr/bin/env -S RUST_LOG=rust_script=warn rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! miette = { version = "7", features = ["fancy"] }
//! thiserror = "2"
//! ```

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use {
    clap::{Parser, Subcommand},
    miette::{Diagnostic, IntoDiagnostic, Result},
    std::{
        env,
        ffi::OsString,
        fs,
        io::Write,
        path::{Path, PathBuf},
        process::{Command, Stdio},
    },
    thiserror::Error,
};

#[derive(Debug, Parser)]
#[command(
    name = "cmd",
    about = "Inspect commands available on PATH.",
    version,
    disable_help_subcommand = true
)]
struct Cli {
    #[command(subcommand)]
    action: Action,
}

#[derive(Debug, Subcommand)]
enum Action {
    /// Print command paths.
    Loc {
        /// Commands to resolve.
        #[arg(required = true)]
        commands: Vec<String>,
    },

    /// Show command source with bat if available, otherwise cat.
    Src {
        /// Commands to show.
        #[arg(required = true)]
        commands: Vec<String>,
    },

    /// Copy command source to clipboard.
    Cp {
        /// Copy raw source without commented headers.
        #[arg(short = 'x', long = "raw")]
        raw: bool,

        /// Commands to copy.
        #[arg(required = true)]
        commands: Vec<String>,
    },
}

#[derive(Debug, Error, Diagnostic)]
enum CmdError {
    #[error("command not found: {0}")]
    #[diagnostic(help("Check that the command exists on PATH."))]
    CommandNotFound(String),

    #[error("neither bat nor cat was found")]
    #[diagnostic(help("Install bat or ensure cat is available on PATH."))]
    ViewerNotFound,

    #[error("no clipboard command found")]
    #[diagnostic(help("Install or expose one of: clip, wl-copy, xclip, pbcopy."))]
    ClipboardNotFound,
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

fn resolve_command(name: &str) -> std::result::Result<PathBuf, CmdError> {
    find_cmd(name).ok_or_else(|| CmdError::CommandNotFound(name.to_string()))
}

fn viewer_command() -> std::result::Result<PathBuf, CmdError> {
    find_cmd("bat")
        .or_else(|| find_cmd("cat"))
        .ok_or(CmdError::ViewerNotFound)
}

fn clipboard_command() -> std::result::Result<(PathBuf, Vec<&'static str>), CmdError> {
    if let Some(path) = find_cmd("clip") {
        return Ok((path, vec![]));
    }

    if let Some(path) = find_cmd("wl-copy") {
        return Ok((path, vec![]));
    }

    if let Some(path) = find_cmd("xclip") {
        return Ok((path, vec!["-selection", "clipboard"]));
    }

    if let Some(path) = find_cmd("pbcopy") {
        return Ok((path, vec![]));
    }

    Err(CmdError::ClipboardNotFound)
}

fn loc(commands: &[String]) -> Result<()> {
    let mut failed = false;

    for command in commands {
        match resolve_command(command) {
            Ok(path) => println!("{}", path.display()),
            Err(error) => {
                eprintln!("{error}");
                failed = true;
            }
        }
    }

    if failed {
        std::process::exit(1);
    }

    Ok(())
}

fn src(commands: &[String]) -> Result<()> {
    let viewer = viewer_command()?;
    let mut failed = false;

    for command in commands {
        let path = match resolve_command(command) {
            Ok(path) => path,
            Err(error) => {
                eprintln!("{error}");
                failed = true;
                continue;
            }
        };

        let status = Command::new(&viewer)
            .arg(&path)
            .status()
            .into_diagnostic()?;

        if !status.success() {
            failed = true;
        }
    }

    if failed {
        std::process::exit(1);
    }

    Ok(())
}

fn cp(commands: &[String], raw: bool) -> Result<()> {
    let mut output = Vec::new();
    let mut failed = false;
    let mut first = true;

    for command in commands {
        let path = match resolve_command(command) {
            Ok(path) => path,
            Err(error) => {
                eprintln!("{error}");
                failed = true;
                continue;
            }
        };

        if !first {
            output.extend_from_slice(b"\n\n");
        }

        first = false;

        if !raw {
            let header = format!("# cmd: {command} ({})\n\n", path.display());
            output.extend_from_slice(header.as_bytes());
        }

        match fs::read(&path) {
            Ok(bytes) => output.extend_from_slice(&bytes),
            Err(error) => {
                eprintln!("failed to read {}: {error}", path.display());
                failed = true;
            }
        }
    }

    if !output.is_empty() {
        let (program, args) = clipboard_command()?;

        let mut child = Command::new(program)
            .args(args)
            .stdin(Stdio::piped())
            .spawn()
            .into_diagnostic()?;

        let Some(stdin) = child.stdin.as_mut() else {
            eprintln!("failed to open clipboard stdin");
            std::process::exit(1);
        };

        stdin.write_all(&output).into_diagnostic()?;

        let status = child.wait().into_diagnostic()?;

        if !status.success() {
            failed = true;
        }
    }

    if failed {
        std::process::exit(1);
    }

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.action {
        Action::Loc { commands } => loc(&commands),
        Action::Src { commands } => src(&commands),
        Action::Cp { raw, commands } => cp(&commands, raw),
    }
}
