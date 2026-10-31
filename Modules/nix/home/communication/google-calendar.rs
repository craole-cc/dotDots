#!/usr/bin/env rust-script
//! Keep Google credentials and generated sync configuration outside the store.
//!
//! Usage: google-calendar.rs VDIRSYNCER [ARGS...]
//!
//! ARGS default to "sync". "setup" runs discover and sync, then marks the
//! setup as ready so the systemd timer starts doing work.
//!
//! ```cargo
//! [dependencies]
//! libc = "0.2"
//! serde_json = "1"
//! ```

use std::env;
use std::fs::{self, DirBuilder, OpenOptions};
use std::io::Write;
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

use serde_json::Value;

const REQUIRED_CLIENT_KEYS: [&str; 2] = ["client_id", "client_secret"];

/// Resolve an XDG directory, treating an empty variable as unset.
fn xdg(variable: &str, fallback: PathBuf) -> PathBuf {
    match env::var_os(variable) {
        Some(value) if !value.is_empty() => PathBuf::from(value),
        _ => fallback,
    }
}

fn load_client(credentials: &Path) -> Result<serde_json::Map<String, Value>, String> {
    if !credentials.is_file() {
        return Err(format!(
            "Save Google's Desktop OAuth client JSON to {} with mode 0600 first.",
            credentials.display()
        ));
    }
    let mode = fs::metadata(credentials)
        .map_err(|error| format!("Cannot stat {}: {error}", credentials.display()))?
        .permissions()
        .mode();
    if mode & 0o077 != 0 {
        return Err(format!("Run chmod 600 {} before continuing.", credentials.display()));
    }
    let text = fs::read_to_string(credentials)
        .map_err(|error| format!("Cannot read {}: {error}", credentials.display()))?;
    let document: Value = serde_json::from_str(&text)
        .map_err(|error| format!("Cannot parse {}: {error}", credentials.display()))?;
    let client = document
        .get("installed")
        .and_then(Value::as_object)
        .ok_or_else(|| {
            format!(
                "{} has no 'installed' section. Create the OAuth client in Google Cloud \
                 as a 'Desktop app', not a web client.",
                credentials.display()
            )
        })?;
    let missing: Vec<&str> = REQUIRED_CLIENT_KEYS
        .iter()
        .copied()
        .filter(|key| client.get(*key).and_then(Value::as_str).map_or(true, str::is_empty))
        .collect();
    if !missing.is_empty() {
        return Err(format!("{} is missing: {}.", credentials.display(), missing.join(", ")));
    }
    Ok(client.clone())
}

/// vdirsyncer reads each value as JSON, so JSON string quoting is the right escaping.
fn quote(text: &str) -> String {
    Value::String(text.to_owned()).to_string()
}

fn create_private_dir(path: &Path) -> Result<(), String> {
    DirBuilder::new()
        .recursive(true)
        .mode(0o700)
        .create(path)
        .map_err(|error| format!("Cannot create {}: {error}", path.display()))
}

/// Create the file as 0600 from the start, fixing the mode if it already existed.
fn write_private(path: &Path, text: &str) -> Result<(), String> {
    let describe = |error: std::io::Error| format!("Cannot write {}: {error}", path.display());
    let mut file = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .mode(0o600)
        .open(path)
        .map_err(describe)?;
    file.set_permissions(fs::Permissions::from_mode(0o600)).map_err(describe)?;
    file.write_all(text.as_bytes()).map_err(describe)
}

fn render_config(client: &serde_json::Map<String, Value>, state: &Path, data: &Path) -> String {
    let field = |key: &str| quote(client[key].as_str().unwrap_or_default());
    format!(
        concat!(
            "[general]\n",
            "status_path = {status}\n",
            "[pair google]\n",
            "a = \"google_remote\"\n",
            "b = \"google_local\"\n",
            "collections = [\"from a\"]\n",
            "[storage google_remote]\n",
            "type = \"google_calendar\"\n",
            "read_only = false\n",
            "token_file = {token}\n",
            "client_id = {client_id}\n",
            "client_secret = {client_secret}\n",
            "[storage google_local]\n",
            "type = \"filesystem\"\n",
            "path = {data}\n",
            "fileext = \".ics\"\n",
        ),
        status = quote(&state.join("status").to_string_lossy()),
        token = quote(&state.join("google-token.json").to_string_lossy()),
        client_id = field("client_id"),
        client_secret = field("client_secret"),
        data = quote(&data.to_string_lossy()),
    )
}

fn run(binary: &str, config: &Path, arguments: &[String]) -> Result<(), String> {
    let status = Command::new(binary)
        .arg("--config")
        .arg(config)
        .args(arguments)
        .status()
        .map_err(|error| format!("Cannot execute {binary}: {error}"))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("{binary} {} failed with {status}.", arguments.join(" ")))
    }
}

fn run_all(binary: &str) -> Result<(), String> {
    let home = PathBuf::from(env::var_os("HOME").ok_or("HOME is not set.")?);
    let config = xdg("XDG_CONFIG_HOME", home.join(".config"));
    let state = xdg("XDG_STATE_HOME", home.join(".local/state")).join("vdirsyncer");
    let data = xdg("XDG_DATA_HOME", home.join(".local/share")).join("calendars/google");

    let client = load_client(&config.join("vdirsyncer/google-client.json"))?;
    create_private_dir(&state)?;
    create_private_dir(&data)?;

    let runtime_config = state.join("google.config");
    write_private(&runtime_config, &render_config(&client, &state, &data))?;

    let mut command: Vec<String> = env::args().skip(2).collect();
    if command.is_empty() {
        command.push("sync".to_owned());
    }
    if command == ["setup"] {
        run(binary, &runtime_config, &["discover".to_owned(), "google".to_owned()])?;
        run(binary, &runtime_config, &["sync".to_owned(), "google".to_owned()])?;
        write_private(&state.join("google.ready"), "")
    } else {
        run(binary, &runtime_config, &command)
    }
}

fn main() -> ExitCode {
    let Some(binary) = env::args().nth(1) else {
        eprintln!("Usage: google-calendar.rs VDIRSYNCER [ARGS...]");
        return ExitCode::FAILURE;
    };
    // Also inherited by vdirsyncer, so its token file is private.
    unsafe { libc::umask(0o077) };
    match run_all(&binary) {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}
