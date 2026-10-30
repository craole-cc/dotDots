#!/usr/bin/env rust-script
//! Configure Gmail and Google calendars from a private runtime environment file.
//!
//! Usage: thunderbird-google.rs [--env PATH] [--profile PATH]
//!
//! ```cargo
//! [dependencies]
//! libc = "0.2"
//! serde_json = { version = "1", features = ["preserve_order"] }
//! uuid = { version = "1", features = ["v5"] }
//! ```

use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{ErrorKind, Write};
use std::os::fd::AsRawFd;
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use serde_json::{json, Map, Value};
use uuid::Uuid;

const DEFAULT_ID: &str = "dotdotsGoogle";
const CALDAV_ROOT: &str = "https://apidata.googleusercontent.com/caldav/v2/";
const ENVIRONMENT_KEYS: [&str; 3] = ["GOOGLE_EMAIL", "GOOGLE_REAL_NAME", "GOOGLE_CALENDAR_IDS"];
const USAGE: &str = "Usage: thunderbird-google.rs [--env PATH] [--profile PATH]";

/// Preferences we generate, sorted by key like the Python version.
type Prefs = BTreeMap<String, Value>;
/// Preferences already in prefs.js, in file order (serde_json's preserve_order).
type Existing = Map<String, Value>;

/// Resolve an XDG directory, treating an empty variable as unset.
fn xdg(variable: &str, fallback: PathBuf) -> PathBuf {
    match env::var_os(variable) {
        Some(value) if !value.is_empty() => PathBuf::from(value),
        _ => fallback,
    }
}

fn valid_email(email: &str) -> bool {
    if email.chars().any(char::is_whitespace) {
        return false;
    }
    let Some((local, domain)) = email.split_once('@') else {
        return false;
    };
    if local.is_empty() || domain.contains('@') {
        return false;
    }
    domain
        .char_indices()
        .any(|(index, character)| character == '.' && index > 0 && index + 1 < domain.len())
}

fn read_environment(path: &Path) -> Result<HashMap<String, String>, String> {
    if !path.is_file() {
        return Err(format!(
            "Create {} from google.env.example and chmod 600 it first.",
            path.display()
        ));
    }
    let mode = fs::metadata(path)
        .map_err(|error| format!("Cannot stat {}: {error}", path.display()))?
        .permissions()
        .mode();
    if mode & 0o077 != 0 {
        return Err(format!(
            "Run chmod 600 {} before continuing.",
            path.display()
        ));
    }
    let text = fs::read_to_string(path)
        .map_err(|error| format!("Cannot read {}: {error}", path.display()))?;
    let mut values = HashMap::new();
    for (index, raw_line) in text.lines().enumerate() {
        let number = index + 1;
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let unsupported = || format!("Unsupported environment entry on line {number}.");
        let (raw_key, raw_value) = line.split_once('=').ok_or_else(unsupported)?;
        let key = raw_key.trim();
        if !ENVIRONMENT_KEYS.contains(&key) {
            return Err(unsupported());
        }
        let mut value = raw_value.trim();
        if let Some(quote) = value
            .chars()
            .next()
            .filter(|first| matches!(first, '\'' | '"'))
        {
            if value.len() < 2 || !value.ends_with(quote) {
                return Err(format!("Unmatched quotes on line {number}."));
            }
            value = &value[1..value.len() - 1];
        }
        values.insert(key.to_owned(), value.to_owned());
    }
    let email = values.get("GOOGLE_EMAIL").map_or("", String::as_str);
    if !valid_email(email) {
        return Err("Set GOOGLE_EMAIL to your Google account address.".to_owned());
    }
    Ok(values)
}

/// Return (key, raw_value) for a `user_pref("key", value);` line, or None for any other line.
fn split_pref(line: &str) -> Option<(String, &str)> {
    let inner = line.strip_prefix("user_pref(")?.strip_suffix(");")?;
    let bytes = inner.as_bytes();
    if bytes.first() != Some(&b'"') {
        return None;
    }
    let mut index = 1;
    while index < bytes.len() {
        match bytes[index] {
            b'\\' => index += 2,
            b'"' => break,
            _ => index += 1,
        }
    }
    if index >= bytes.len() {
        return None;
    }
    let key = serde_json::from_str::<String>(&inner[..=index]).ok()?;
    let raw_value = inner[index + 1..].strip_prefix(", ")?;
    Some((key, raw_value))
}

fn read_prefs(text: &str) -> Existing {
    let mut existing = Existing::new();
    for line in text.lines() {
        if let Some((key, raw_value)) = split_pref(line) {
            if let Ok(value) = serde_json::from_str::<Value>(raw_value) {
                existing.insert(key, value);
            }
        }
    }
    existing
}

/// Like Python's quote(text, safe="").
fn percent_encode(text: &str) -> String {
    let mut encoded = String::new();
    for byte in text.bytes() {
        if byte.is_ascii_alphanumeric() || matches!(byte, b'_' | b'.' | b'-' | b'~') {
            encoded.push(byte as char);
        } else {
            encoded.push_str(&format!("%{byte:02X}"));
        }
    }
    encoded
}

/// Like Python's unquote(text).
fn percent_decode(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        let escaped = (bytes[index] == b'%' && index + 2 < bytes.len())
            .then(|| &bytes[index + 1..index + 3])
            .filter(|digits| digits.iter().all(u8::is_ascii_hexdigit))
            .and_then(|digits| std::str::from_utf8(digits).ok())
            .and_then(|digits| u8::from_str_radix(digits, 16).ok());
        match escaped {
            Some(byte) => {
                decoded.push(byte);
                index += 3;
            }
            None => {
                decoded.push(bytes[index]);
                index += 1;
            }
        }
    }
    String::from_utf8_lossy(&decoded).into_owned()
}

/// Like Python's json.dumps for scalars: compact, with non-ASCII escaped as \uXXXX.
fn dumps(value: &Value) -> String {
    let mut output = String::new();
    for character in value.to_string().chars() {
        if character.is_ascii() {
            output.push(character);
        } else {
            let mut units = [0u16; 2];
            for unit in character.encode_utf16(&mut units) {
                output.push_str(&format!("\\u{unit:04x}"));
            }
        }
    }
    output
}

fn text_of(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        other => other.to_string(),
    }
}

fn is_truthy(value: &Value) -> bool {
    match value {
        Value::Null => false,
        Value::Bool(flag) => *flag,
        Value::Number(number) => number.as_f64() != Some(0.0),
        Value::String(text) => !text.is_empty(),
        Value::Array(items) => !items.is_empty(),
        Value::Object(entries) => !entries.is_empty(),
    }
}

/// The existing value for `key` if it is set and non-empty, else `fallback`.
fn existing_or(existing: &Existing, key: &str, fallback: &str) -> String {
    existing
        .get(key)
        .filter(|value| is_truthy(value))
        .map_or_else(|| fallback.to_owned(), text_of)
}

/// Name of the first existing entry under `prefix`..`suffix` whose value matches, else the default.
fn first_id(
    existing: &Existing,
    prefix: &str,
    suffix: &str,
    matches: impl Fn(&Value) -> bool,
) -> String {
    existing
        .iter()
        .find_map(|(key, value)| {
            let wanted = key.starts_with(prefix) && key.ends_with(suffix) && matches(value);
            wanted
                .then(|| key.split('.').nth(2).map(str::to_owned))
                .flatten()
        })
        .unwrap_or_else(|| DEFAULT_ID.to_owned())
}

fn append_item(prefs: &mut Prefs, existing: &Existing, key: &str, item: &str, separator: char) {
    let current = prefs
        .get(key)
        .or_else(|| existing.get(key))
        .map(text_of)
        .unwrap_or_default();
    let mut items: Vec<&str> = Vec::new();
    for entry in current.split(separator).chain(std::iter::once(item)) {
        if !entry.is_empty() && !items.contains(&entry) {
            items.push(entry);
        }
    }
    let joined = items.join(&separator.to_string());
    prefs.insert(key.to_owned(), Value::String(joined));
}

fn add_calendars(
    prefs: &mut Prefs,
    existing: &Existing,
    values: &HashMap<String, String>,
    identity: &str,
) {
    let email = &values["GOOGLE_EMAIL"];
    let configured = values
        .get("GOOGLE_CALENDAR_IDS")
        .filter(|ids| !ids.is_empty())
        .unwrap_or(email);
    let mut seen: Vec<&str> = Vec::new();
    for calendar_id in configured
        .split(',')
        .map(str::trim)
        .filter(|id| !id.is_empty())
    {
        if seen.contains(&calendar_id) {
            continue;
        }
        seen.push(calendar_id);
        let uri = format!("{CALDAV_ROOT}{}/events/", percent_encode(calendar_id));
        let wanted = percent_decode(&uri);
        // Reuse a calendar registered earlier (by this script or by hand) for the same URI.
        let calendar = existing
            .iter()
            .find_map(|(key, value)| {
                let same = key.starts_with("calendar.registry.")
                    && key.ends_with(".uri")
                    && percent_decode(&text_of(value)).trim_end_matches('/')
                        == wanted.trim_end_matches('/');
                same.then(|| key.split('.').nth(2).map(str::to_owned))
                    .flatten()
            })
            .unwrap_or_else(|| {
                Uuid::new_v5(
                    &Uuid::NAMESPACE_URL,
                    format!("google-calendar:{calendar_id}").as_bytes(),
                )
                .to_string()
            });
        let prefix = format!("calendar.registry.{calendar}.");
        let entries = [
            ("type", json!("caldav")),
            ("uri", json!(uri)),
            ("name", json!(format!("Google: {calendar_id}"))),
            ("username", json!(email)),
            ("imip.identity.key", json!(identity)),
            ("disabled", json!(false)),
            ("readOnly", json!(false)),
            ("cache.enabled", json!(true)),
        ];
        for (suffix, value) in entries {
            prefs.insert(format!("{prefix}{suffix}"), value);
        }
        append_item(prefs, existing, "calendar.list.sortOrder", &calendar, ' ');
    }
}

fn build_prefs(existing: &Existing, values: &HashMap<String, String>) -> Prefs {
    let email = &values["GOOGLE_EMAIL"];
    // Reuse a matching account left by Home Manager or manual setup.
    let identity = first_id(existing, "mail.identity.", ".useremail", |value| {
        value.as_str() == Some(email.as_str())
    });
    let account = first_id(existing, "mail.account.", ".identities", |value| {
        text_of(value).split(',').any(|item| item == identity)
    });
    let server = existing_or(
        existing,
        &format!("mail.account.{account}.server"),
        DEFAULT_ID,
    );
    let smtp = existing_or(
        existing,
        &format!("mail.identity.{identity}.smtpServer"),
        DEFAULT_ID,
    );
    let identities_key = format!("mail.account.{account}.identities");
    let real_name = values
        .get("GOOGLE_REAL_NAME")
        .filter(|name| !name.is_empty())
        .unwrap_or(email);
    let entries = [
        (
            identities_key.clone(),
            json!(existing_or(existing, &identities_key, &identity)),
        ),
        (format!("mail.account.{account}.server"), json!(server)),
        (format!("mail.identity.{identity}.useremail"), json!(email)),
        (
            format!("mail.identity.{identity}.fullName"),
            json!(real_name),
        ),
        (format!("mail.identity.{identity}.smtpServer"), json!(smtp)),
        (format!("mail.identity.{identity}.valid"), json!(true)),
        (format!("mail.server.{server}.type"), json!("imap")),
        (
            format!("mail.server.{server}.hostname"),
            json!("imap.gmail.com"),
        ),
        (format!("mail.server.{server}.userName"), json!(email)),
        (format!("mail.server.{server}.name"), json!(email)),
        (format!("mail.server.{server}.port"), json!(993)),
        (format!("mail.server.{server}.socketType"), json!(3)),
        (format!("mail.server.{server}.authMethod"), json!(10)),
        (
            format!("mail.server.{server}.login_at_startup"),
            json!(true),
        ),
        (format!("mail.server.{server}.check_new_mail"), json!(true)),
        (
            format!("mail.smtpserver.{smtp}.hostname"),
            json!("smtp.gmail.com"),
        ),
        (format!("mail.smtpserver.{smtp}.username"), json!(email)),
        (format!("mail.smtpserver.{smtp}.port"), json!(465)),
        (format!("mail.smtpserver.{smtp}.try_ssl"), json!(3)),
        (format!("mail.smtpserver.{smtp}.authMethod"), json!(10)),
    ];
    let mut prefs: Prefs = entries.into_iter().collect();
    append_item(
        &mut prefs,
        existing,
        "mail.accountmanager.accounts",
        &account,
        ',',
    );
    append_item(&mut prefs, existing, "mail.smtpservers", &smtp, ',');
    prefs.insert(
        "mail.accountmanager.defaultaccount".to_owned(),
        json!(existing_or(
            existing,
            "mail.accountmanager.defaultaccount",
            &account
        )),
    );
    prefs.insert(
        "mail.smtp.defaultserver".to_owned(),
        json!(existing_or(existing, "mail.smtp.defaultserver", &smtp)),
    );
    add_calendars(&mut prefs, existing, values, &identity);
    prefs
}

/// Keep unrelated preferences and replace ours without duplicates.
fn merge_prefs(original: &str, prefs: &Prefs) -> String {
    let retained: Vec<&str> = original
        .lines()
        .filter(|line| !matches!(split_pref(line), Some((key, _)) if prefs.contains_key(&key)))
        .collect();
    let generated: Vec<String> = prefs
        .iter()
        .map(|(key, value)| {
            format!(
                "user_pref({}, {});",
                dumps(&Value::String(key.clone())),
                dumps(value)
            )
        })
        .collect();
    format!(
        "{}\n{}\n",
        retained.join("\n").trim_end(),
        generated.join("\n")
    )
}

/// Keep the original profile for recovery and replace prefs atomically.
fn save(profile: &Path, path: &Path, original: &str, result: &str) -> Result<(), String> {
    let backup = profile.join("prefs.js.before-google-setup");
    match OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(&backup)
    {
        Ok(mut file) => file
            .write_all(original.as_bytes())
            .map_err(|error| format!("Cannot write {}: {error}", backup.display()))?,
        Err(error) if error.kind() == ErrorKind::AlreadyExists => {}
        Err(error) => return Err(format!("Cannot create {}: {error}", backup.display())),
    }
    let temporary = profile.join(format!("prefs.js.tmp-{}", std::process::id()));
    let outcome = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .mode(0o600)
        .open(&temporary)
        .and_then(|mut file| file.write_all(result.as_bytes()))
        .and_then(|()| fs::rename(&temporary, path));
    if outcome.is_err() {
        let _ = fs::remove_file(&temporary);
    }
    outcome.map_err(|error| format!("Cannot write {}: {error}", path.display()))
}

fn configure(profile: &Path, values: &HashMap<String, String>) -> Result<(), String> {
    // Thunderbird's own lock files; run() separately holds a POSIX lock on .parentlock.
    for name in ["lock", "parent.lock"] {
        if fs::symlink_metadata(profile.join(name)).is_ok() {
            return Err("Close Thunderbird and release its profile lock before setup.".to_owned());
        }
    }
    let path = profile.join("prefs.js");
    if path.is_symlink() {
        return Err("prefs.js must be a writable profile file, not a symlink.".to_owned());
    }
    let original = match fs::read_to_string(&path) {
        Ok(text) => text,
        Err(error) if error.kind() == ErrorKind::NotFound => String::new(),
        Err(error) => return Err(format!("Cannot read {}: {error}", path.display())),
    };
    let prefs = build_prefs(&read_prefs(&original), values);
    save(profile, &path, &original, &merge_prefs(&original, &prefs))
}

/// Take a non-blocking exclusive POSIX lock, the same call Python's fcntl.lockf makes.
fn lock_exclusive(file: &File) -> std::io::Result<()> {
    let mut request: libc::flock = unsafe { std::mem::zeroed() };
    request.l_type = libc::F_WRLCK as _;
    request.l_whence = libc::SEEK_SET as _;
    let result = unsafe { libc::fcntl(file.as_raw_fd(), libc::F_SETLK, &request) };
    if result == -1 {
        Err(std::io::Error::last_os_error())
    } else {
        Ok(())
    }
}

fn run(env_path: &Path, profile: &Path) -> Result<(), String> {
    let values = read_environment(env_path)?;
    if !profile.is_dir() {
        return Err(
            "Open Thunderbird's google profile once, then close it before setup.".to_owned(),
        );
    }
    let lock_path = profile.join(".parentlock");
    if lock_path.is_symlink() {
        return Err("The profile's .parentlock must not be a symlink.".to_owned());
    }
    // Mozilla retains this file after exit; hold its POSIX lock while writing.
    let lock = OpenOptions::new()
        .read(true)
        .append(true)
        .create(true)
        .open(&lock_path)
        .map_err(|error| format!("Cannot open {}: {error}", lock_path.display()))?;
    lock_exclusive(&lock).map_err(|_| "Close Thunderbird before running setup.".to_owned())?;
    configure(profile, &values)
}

/// Returns None when --help was printed.
fn parse_arguments(
    mut env_path: PathBuf,
    mut profile: PathBuf,
) -> Result<Option<(PathBuf, PathBuf)>, String> {
    let mut arguments = env::args().skip(1);
    while let Some(argument) = arguments.next() {
        let (flag, inline) = match argument.split_once('=') {
            Some((flag, value)) => (flag.to_owned(), Some(value.to_owned())),
            None => (argument.clone(), None),
        };
        match flag.as_str() {
            "-h" | "--help" => {
                println!("{USAGE}");
                return Ok(None);
            }
            "--env" | "--profile" => {
                let value = inline
                    .or_else(|| arguments.next())
                    .ok_or_else(|| format!("{flag} needs a value."))?;
                if flag == "--env" {
                    env_path = value.into();
                } else {
                    profile = value.into();
                }
            }
            other => return Err(format!("Unknown argument: {other}\n{USAGE}")),
        }
    }
    Ok(Some((env_path, profile)))
}

fn main() -> ExitCode {
    unsafe { libc::umask(0o077) };
    let Some(home) = env::var_os("HOME").map(PathBuf::from) else {
        eprintln!("HOME is not set.");
        return ExitCode::FAILURE;
    };
    let default_env = xdg("XDG_CONFIG_HOME", home.join(".config")).join("thunderbird/google.env");
    let default_profile = home.join(".thunderbird/google");
    let outcome = parse_arguments(default_env, default_profile).and_then(|parsed| match parsed {
        None => Ok(false),
        Some((env_path, profile)) => run(&env_path, &profile).map(|()| true),
    });
    match outcome {
        Ok(true) => {
            println!("Google mail and calendars configured. Open Thunderbird and complete Google sign-in.");
            ExitCode::SUCCESS
        }
        Ok(false) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}
