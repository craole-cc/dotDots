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
        fs,
        path::{Path, PathBuf},
        process::Command,
    },
    thiserror::Error,
};

const DB_PATH: &str = "database/data/portfolio.db";
const MIGRATIONS_DIR: &str = "database/migrations";
const ENV_FILE: &str = ".env";

#[derive(Debug, Parser)]
#[command(
    name = "init-db",
    about = "Initialise the local SQLite database for craole.cc.",
    disable_help_subcommand = true
)]
struct Cli {
    /// Remove and recreate the database if it already exists.
    #[arg(short = 'f', long = "force", alias = "reset")]
    force: bool,
}

#[derive(Debug, Error, Diagnostic)]
enum InitDbError {
    #[error("run this script from the workspace root")]
    #[diagnostic(help("The current directory must contain Cargo.toml."))]
    NotWorkspaceRoot,

    #[error("required command not found: {0}")]
    #[diagnostic(help(
        "Install sqlx-cli with: cargo install sqlx-cli --no-default-features --features sqlite"
    ))]
    RequiredCommandNotFound(String),

    #[error("command failed: {0}")]
    CommandFailed(String),
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

fn require_cmd(name: &str) -> Result<PathBuf> {
    find_cmd(name)
        .ok_or_else(|| InitDbError::RequiredCommandNotFound(name.to_string()))
        .map_err(Into::into)
}

fn read_database_url_from_env_file(path: &Path) -> Result<Option<String>> {
    if !path.is_file() {
        return Ok(None);
    }

    let content = fs::read_to_string(path).into_diagnostic()?;

    let value = content
        .lines()
        .filter_map(|line| {
            let trimmed = line.trim_start();

            if trimmed.starts_with('#') {
                return None;
            }

            trimmed.strip_prefix("DATABASE_URL=").map(|value| {
                value
                    .trim()
                    .trim_matches('"')
                    .trim_matches('\'')
                    .to_string()
            })
        })
        .last();

    Ok(value)
}

fn database_url() -> Result<String> {
    if let Ok(value) = env::var("DATABASE_URL") {
        if !value.trim().is_empty() {
            return Ok(value);
        }
    }

    if let Some(value) = read_database_url_from_env_file(Path::new(ENV_FILE))? {
        if !value.trim().is_empty() {
            return Ok(value);
        }
    }

    Ok(format!("sqlite:./{DB_PATH}"))
}

fn info(message: impl AsRef<str>) {
    eprintln!("init-db: {}", message.as_ref());
}

fn success(message: impl AsRef<str>) {
    eprintln!("init-db: ✔ {}", message.as_ref());
}

fn warning(message: impl AsRef<str>) {
    eprintln!("init-db: ⚠ {}", message.as_ref());
}

fn ensure_workspace_root() -> Result<()> {
    if !Path::new("Cargo.toml").is_file() {
        return Err(InitDbError::NotWorkspaceRoot.into());
    }

    Ok(())
}

fn run_sqlx_migrations(sqlx: &Path, database_url: &str) -> Result<()> {
    let status = Command::new(sqlx)
        .args([
            "migrate",
            "run",
            "--source",
            MIGRATIONS_DIR,
            "--database-url",
            database_url,
        ])
        .status()
        .into_diagnostic()?;

    if !status.success() {
        return Err(InitDbError::CommandFailed("sqlx migrate run".to_string()).into());
    }

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    ensure_workspace_root()?;

    let sqlx = require_cmd("sqlx")?;
    let db_path = Path::new(DB_PATH);
    let database_url = database_url()?;

    info(format!("Database URL: {database_url}"));

    if db_path.is_file() {
        if cli.force {
            warning("Removing existing database (--force)...");
            fs::remove_file(db_path).into_diagnostic()?;
        } else {
            success(
                "Database already exists. Skipping. Use -f / --force / --reset to reinitialise.",
            );
            return Ok(());
        }
    }

    info("Creating database directory...");

    if let Some(parent) = db_path.parent() {
        fs::create_dir_all(parent).into_diagnostic()?;
    }

    fs::File::create(db_path).into_diagnostic()?;

    info(format!("Running migrations from {MIGRATIONS_DIR}..."));
    run_sqlx_migrations(&sqlx, &database_url)?;

    success(format!("Done. Database initialised at {DB_PATH}"));

    Ok(())
}
