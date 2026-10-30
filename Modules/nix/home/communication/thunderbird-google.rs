#!/usr/bin/env rust-script
//! Configure Gmail and Google calendars from a private TOML or legacy environment file.
//!
//! Usage: thunderbird-google.rs [--config PATH] [--profile PATH]
//!
//! ```cargo
//! [dependencies]
//! libc = "0.2"
//! oauth2 = { version = "4.4", default-features = false }
//! serde_json = { version = "1", features = ["preserve_order"] }
//! toml = "0.8"
//! ureq = { version = "2", features = ["json"] }
//! url = "2"
//! uuid = { version = "1", features = ["v5"] }
//! ```

use std::collections::{BTreeMap, HashMap};
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{BufRead, BufReader, ErrorKind, Read, Write};
use std::net::TcpListener;
use std::os::fd::AsRawFd;
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};
use std::time::{Duration, Instant};

use oauth2::{
    basic::BasicClient, AuthType, AuthUrl, AuthorizationCode, ClientId, ClientSecret, CsrfToken,
    PkceCodeChallenge, RedirectUrl, RefreshToken, Scope, TokenResponse, TokenUrl,
};

use serde_json::{json, Map, Value};
use uuid::Uuid;

const CALDAV_ROOT: &str = "https://apidata.googleusercontent.com/caldav/v2/";
const ENVIRONMENT_KEYS: [&str; 5] = [
    "GOOGLE_EMAIL",
    "GOOGLE_EMAILS",
    "GOOGLE_REAL_NAME",
    "GOOGLE_REAL_NAMES",
    "GOOGLE_CALENDAR_IDS",
];
const USAGE: &str = "Usage: thunderbird-google.rs [--config PATH] [--profile PATH]";

/// Preferences we generate, sorted by key like the Python version.
type Prefs = BTreeMap<String, Value>;
/// Preferences already in prefs.js, in file order (serde_json's preserve_order).
type Existing = Map<String, Value>;

#[derive(Clone)]
struct Account {
    email: String,
    real_name: Option<String>,
    calendar_ids: Vec<String>,
    calendars: Vec<Calendar>,
}

#[derive(Clone)]
struct Calendar {
    id: String,
    name: String,
    read_only: bool,
}

struct SetupConfig {
    accounts: Vec<Account>,
    oauth_client: PathBuf,
}

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

fn read_legacy_environment(path: &Path) -> Result<Vec<Account>, String> {
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
    let emails = values
        .get("GOOGLE_EMAILS")
        .map(String::as_str)
        .or_else(|| values.get("GOOGLE_EMAIL").map(String::as_str))
        .unwrap_or("");
    let emails: Vec<_> = emails
        .split(',')
        .map(str::trim)
        .filter(|email| !email.is_empty())
        .collect();
    if emails.is_empty() || emails.iter().any(|email| !valid_email(email)) {
        return Err("Set GOOGLE_EMAIL or a comma-separated GOOGLE_EMAILS list to valid Google account addresses.".to_owned());
    }
    if let Some(names) = values.get("GOOGLE_REAL_NAMES") {
        if values.contains_key("GOOGLE_REAL_NAME") {
            return Err("Use GOOGLE_REAL_NAMES or GOOGLE_REAL_NAME, not both.".to_owned());
        }
        let names: Vec<_> = names.split(',').map(str::trim).collect();
        if names.len() != emails.len() || names.iter().any(|name| name.is_empty()) {
            return Err("GOOGLE_REAL_NAMES must contain one non-empty name for each address in GOOGLE_EMAILS, in the same order.".to_owned());
        }
    }
    Ok(emails
        .iter()
        .enumerate()
        .map(|(index, email)| Account {
            calendars: Vec::new(),
            email: (*email).to_owned(),
            real_name: values
                .get("GOOGLE_REAL_NAMES")
                .map(|names| {
                    names
                        .split(',')
                        .map(str::trim)
                        .nth(index)
                        .unwrap_or_default()
                        .to_owned()
                })
                .or_else(|| values.get("GOOGLE_REAL_NAME").cloned()),
            calendar_ids: if index == 0 {
                values
                    .get("GOOGLE_CALENDAR_IDS")
                    .into_iter()
                    .flat_map(|ids| ids.split(','))
                    .map(str::trim)
                    .filter(|id| !id.is_empty())
                    .map(str::to_owned)
                    .collect()
            } else {
                Vec::new()
            },
        })
        .collect())
}

fn read_toml(path: &Path, text: &str) -> Result<Vec<Account>, String> {
    let document: toml::Value = toml::from_str(text)
        .map_err(|error| format!("Cannot parse {}: {error}", path.display()))?;
    let accounts = document
        .get("thunderbird")
        .and_then(|section| section.get("accounts"))
        .or_else(|| document.get("accounts"))
        .and_then(toml::Value::as_array)
        .ok_or_else(|| "TOML config needs a [[thunderbird.accounts]] array.".to_owned())?;
    if accounts.is_empty() {
        return Err("Add at least one [[accounts]] entry to the TOML config.".to_owned());
    }
    accounts
        .iter()
        .map(|entry| {
            let table = entry
                .as_table()
                .ok_or("Each [[accounts]] entry must be a TOML table.")?;
            let email = table
                .get("email")
                .and_then(toml::Value::as_str)
                .ok_or("Each account needs an email string.")?
                .to_owned();
            if !valid_email(&email) {
                return Err("Each account email must be a valid address.".to_owned());
            }
            let real_name = table
                .get("real_name")
                .map(|value| {
                    value
                        .as_str()
                        .map(str::to_owned)
                        .ok_or("real_name must be a string.")
                })
                .transpose()?;
            let calendar_ids = table
                .get("calendar_ids")
                .map(|value| {
                    value
                        .as_array()
                        .ok_or("calendar_ids must be an array of strings.")?
                        .iter()
                        .map(|id| {
                            id.as_str()
                                .map(str::to_owned)
                                .ok_or("calendar_ids must contain only strings.")
                        })
                        .collect::<Result<Vec<_>, _>>()
                })
                .transpose()?
                .unwrap_or_default();
            Ok(Account {
                email,
                real_name,
                calendar_ids,
                calendars: Vec::new(),
            })
        })
        .collect()
}

fn read_config(path: &Path) -> Result<SetupConfig, String> {
    if !path.is_file() {
        return Err(format!(
            "Create {} with a [[thunderbird.accounts]] section and chmod 600 it first.",
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
    let home = PathBuf::from(env::var_os("HOME").ok_or("HOME is not set.")?);
    let default_client =
        xdg("XDG_CONFIG_HOME", home.join(".config")).join("vdirsyncer/google-client.json");
    let (accounts, oauth_client) =
        if path.extension().and_then(|extension| extension.to_str()) == Some("toml") {
            let document: toml::Value = toml::from_str(&text)
                .map_err(|_| "Cannot parse the private TOML config.".to_owned())?;
            let section = document.get("thunderbird").unwrap_or(&document);
            let client = section
                .get("oauth_client")
                .map(|value| {
                    let value = value
                        .as_str()
                        .ok_or("oauth_client must be a file path string.")?;
                    Ok::<PathBuf, String>(if let Some(relative) = value.strip_prefix("~/") {
                        home.join(relative)
                    } else {
                        PathBuf::from(value)
                    })
                })
                .transpose()?
                .unwrap_or(default_client);
            (read_toml(path, &text)?, client)
        } else {
            (read_legacy_environment(path)?, default_client)
        };
    Ok(SetupConfig {
        accounts,
        oauth_client,
    })
}

fn private_json(path: &Path) -> Result<Value, String> {
    let mode = fs::metadata(path)
        .map_err(|_| {
            format!(
                "Cannot read {}. Save a Google Desktop OAuth client JSON there first.",
                path.display()
            )
        })?
        .permissions()
        .mode();
    if mode & 0o077 != 0 {
        return Err(format!(
            "Run chmod 600 {} before continuing.",
            path.display()
        ));
    }
    let text = fs::read_to_string(path).map_err(|_| format!("Cannot read {}.", path.display()))?;
    serde_json::from_str(&text).map_err(|_| format!("Invalid JSON in {}.", path.display()))
}

/// Accept only the callback matching this authorisation's state on our loopback listener.
fn receive_code(listener: &TcpListener, state: &str) -> Result<String, String> {
    listener
        .set_nonblocking(true)
        .map_err(|_| "Cannot configure OAuth callback listener.")?;
    let deadline = Instant::now() + Duration::from_secs(600);
    while Instant::now() < deadline {
        let (mut stream, _) = match listener.accept() {
            Ok(connection) => connection,
            Err(error) if error.kind() == ErrorKind::WouldBlock => {
                std::thread::sleep(Duration::from_millis(100));
                continue;
            }
            Err(_) => return Err("Cannot accept OAuth callback.".to_owned()),
        };
        stream
            .set_read_timeout(Some(Duration::from_secs(5)))
            .map_err(|_| "Cannot set callback timeout.")?;
        let mut request = String::new();
        BufReader::new(&stream)
            .take(8192)
            .read_line(&mut request)
            .map_err(|_| "Cannot read OAuth callback.")?;
        let target = request.split_whitespace().nth(1).unwrap_or("");
        let callback = url::Url::parse(&format!("http://127.0.0.1{target}"))
            .map_err(|_| "Invalid OAuth callback.")?;
        let mut parameters: HashMap<_, _> = callback.query_pairs().into_owned().collect();
        if parameters.get("state").map(String::as_str) != Some(state) {
            let _ = stream
                .write_all(b"HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\nInvalid state.");
            continue;
        }
        let _ = stream.write_all(b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\nReturn to the terminal to finish calendar setup.");
        if parameters.contains_key("error") {
            return Err("Google calendar discovery authorisation was declined.".to_owned());
        }
        return parameters
            .remove("code")
            .ok_or_else(|| "Google returned no authorisation code.".to_owned());
    }
    Err("Timed out waiting for Google sign-in; run setup again.".to_owned())
}

fn google_json(agent: &ureq::Agent, endpoint: &str, token: &str) -> Result<Value, String> {
    agent.get(endpoint).set("Authorization", &format!("Bearer {token}"))
        .call().map_err(|error| match error {
            ureq::Error::Status(status, _) => format!("Google calendar discovery returned HTTP {status}. Enable Google Calendar API for the OAuth project and grant calendar-list access."),
            _ => "Cannot connect to Google calendar discovery.".to_owned(),
        })?
        .into_json().map_err(|_| "Google returned an invalid discovery response.".to_owned())
}

fn token_http_client(request: oauth2::HttpRequest) -> Result<oauth2::HttpResponse, std::io::Error> {
    token_http_response(request).map_err(std::io::Error::other)
}

fn token_http_response(request: oauth2::HttpRequest) -> Result<oauth2::HttpResponse, String> {
    let agent = ureq::AgentBuilder::new()
        .redirects(0)
        .timeout(Duration::from_secs(30))
        .build();
    let mut outgoing = agent.request(request.method.as_str(), request.url.as_str());
    for (name, value) in &request.headers {
        outgoing = outgoing.set(
            name.as_str(),
            value
                .to_str()
                .map_err(|_| "Invalid OAuth request header.")?,
        );
    }
    let response = match outgoing.send_bytes(&request.body) {
        Ok(response) | Err(ureq::Error::Status(_, response)) => response,
        Err(_) => return Err("Cannot connect to Google's authorisation server.".to_owned()),
    };
    let status_code = oauth2::http::StatusCode::from_u16(response.status())
        .map_err(|_| "Invalid OAuth response status.")?;
    let mut headers = oauth2::http::HeaderMap::new();
    if let Some(content_type) = response.header("Content-Type") {
        headers.insert(
            oauth2::http::header::CONTENT_TYPE,
            oauth2::http::HeaderValue::from_str(content_type)
                .map_err(|_| "Invalid OAuth response type.")?,
        );
    }
    let mut body = Vec::new();
    response
        .into_reader()
        .take(1024 * 1024)
        .read_to_end(&mut body)
        .map_err(|_| "Cannot read OAuth response.")?;
    Ok(oauth2::HttpResponse {
        status_code,
        headers,
        body,
    })
}

fn verify_account(agent: &ureq::Agent, token: &str, email: &str) -> Result<(), String> {
    let profile = google_json(
        agent,
        "https://openidconnect.googleapis.com/v1/userinfo",
        token,
    )?;
    check_account_email(&profile, email)
}

fn check_account_email(profile: &Value, email: &str) -> Result<(), String> {
    if !profile
        .get("email")
        .and_then(Value::as_str)
        .is_some_and(|actual| actual.eq_ignore_ascii_case(email))
    {
        return Err(format!("Sign in with {email} when authorising this account; Google returned a different account."));
    }
    Ok(())
}

fn save_refresh_token(path: &Path, client_id: &str, refresh_token: &str) -> Result<(), String> {
    let temporary = path.with_extension(format!(
        "{}.tmp",
        Uuid::new_v5(
            &Uuid::NAMESPACE_URL,
            format!("{}:{:?}", std::process::id(), Instant::now()).as_bytes()
        )
    ));
    let result = (|| -> std::io::Result<()> {
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .open(&temporary)?;
        file.write_all(
            json!({"client_id": client_id, "refresh_token": refresh_token})
                .to_string()
                .as_bytes(),
        )?;
        file.sync_all()?;
        fs::rename(&temporary, path)
    })();
    if result.is_err() {
        let _ = fs::remove_file(&temporary);
    }
    result.map_err(|_| "Cannot save private OAuth authorisation.".to_owned())
}

fn discover_calendars(config: &mut SetupConfig) -> Result<(), String> {
    let credentials = private_json(&config.oauth_client)?;
    let installed = credentials
        .get("installed")
        .ok_or("OAuth client JSON must contain an 'installed' Desktop app client.")?;
    let client_id = installed
        .get("client_id")
        .and_then(Value::as_str)
        .filter(|value| !value.is_empty())
        .ok_or("OAuth client JSON has no client_id.")?;
    let secret = installed
        .get("client_secret")
        .and_then(Value::as_str)
        .ok_or("OAuth client JSON has no client_secret.")?;
    let home = PathBuf::from(env::var_os("HOME").ok_or("HOME is not set.")?);
    let tokens_dir =
        xdg("XDG_STATE_HOME", home.join(".local/state")).join("thunderbird-google/oauth");
    fs::create_dir_all(&tokens_dir).map_err(|_| "Cannot create private OAuth token directory.")?;
    fs::set_permissions(&tokens_dir, fs::Permissions::from_mode(0o700))
        .map_err(|_| "Cannot protect OAuth token directory.")?;
    let agent = ureq::AgentBuilder::new()
        .redirects(0)
        .timeout(Duration::from_secs(30))
        .build();
    for account in &mut config.accounts {
        let cache_path = tokens_dir.join(format!(
            "{}.json",
            Uuid::new_v5(
                &Uuid::NAMESPACE_URL,
                account.email.to_lowercase().as_bytes()
            )
        ));
        let client = BasicClient::new(
            ClientId::new(client_id.to_owned()),
            Some(ClientSecret::new(secret.to_owned())),
            AuthUrl::new("https://accounts.google.com/o/oauth2/v2/auth".to_owned()).unwrap(),
            Some(TokenUrl::new("https://oauth2.googleapis.com/token".to_owned()).unwrap()),
        )
        .set_auth_type(AuthType::RequestBody);
        let cached = if cache_path.exists() {
            Some(private_json(&cache_path)?)
        } else {
            None
        };
        let refresh = cached
            .as_ref()
            .filter(|cache| cache.get("client_id").and_then(Value::as_str) == Some(client_id))
            .and_then(|cache| cache.get("refresh_token"))
            .and_then(Value::as_str);
        let renewed = if let Some(refresh) = refresh {
            match client
                .exchange_refresh_token(&RefreshToken::new(refresh.to_owned()))
                .request(token_http_client) {
                    Ok(token) => Some(token),
                    Err(oauth2::RequestTokenError::ServerResponse(response))
                        if response.error() == &oauth2::basic::BasicErrorResponseType::InvalidGrant => None,
                    Err(_) => return Err("Cannot renew Google calendar discovery access; check your connection and OAuth client, then run setup again.".to_owned()),
                }
        } else {
            None
        };
        let (token, refresh_token) = if let Some(token) = renewed {
            let refresh_token = token
                .refresh_token()
                .map(|value| value.secret().clone())
                .or_else(|| refresh.map(str::to_owned))
                .ok_or("Google returned no refresh token.")?;
            (token.access_token().secret().clone(), refresh_token)
        } else {
            let listener = TcpListener::bind("127.0.0.1:0")
                .map_err(|_| "Cannot open local OAuth callback listener.")?;
            let port = listener
                .local_addr()
                .map_err(|_| "Cannot read local callback port.")?
                .port();
            let client = client
                .set_redirect_uri(RedirectUrl::new(format!("http://127.0.0.1:{port}/")).unwrap());
            let (challenge, verifier) = PkceCodeChallenge::new_random_sha256();
            let (auth_url, state) = client
                .authorize_url(CsrfToken::new_random)
                .add_scope(Scope::new("openid".to_owned()))
                .add_scope(Scope::new("email".to_owned()))
                .add_scope(Scope::new(
                    "https://www.googleapis.com/auth/calendar.calendarlist.readonly".to_owned(),
                ))
                .set_pkce_challenge(challenge)
                .add_extra_param("access_type", "offline")
                .add_extra_param("prompt", "consent")
                .add_extra_param("login_hint", account.email.as_str())
                .url();
            println!(
                "Authorise calendar discovery for {} in your browser.",
                account.email
            );
            if Command::new("xdg-open")
                .arg(auth_url.as_str())
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .status()
                .map_or(true, |status| !status.success())
            {
                println!("Open this sign-in URL: {auth_url}");
            }
            let code = receive_code(&listener, state.secret())?;
            let token = client
                .exchange_code(AuthorizationCode::new(code))
                .set_pkce_verifier(verifier)
                .request(token_http_client)
                .map_err(|_| {
                    "Google could not complete calendar discovery authorisation.".to_owned()
                })?;
            let refresh = token.refresh_token().ok_or(
                "Google returned no offline authorisation; run setup again and grant access.",
            )?;
            (
                token.access_token().secret().clone(),
                refresh.secret().clone(),
            )
        };
        verify_account(&agent, &token, &account.email)?;
        save_refresh_token(&cache_path, client_id, &refresh_token)?;
        account.calendars = fetch_calendars(|endpoint| google_json(&agent, endpoint, &token))?;
        if account.calendars.is_empty() {
            return Err(format!(
                "Google returned no calendars for {}.",
                account.email
            ));
        }
        println!(
            "Discovered {} calendars for {}.",
            account.calendars.len(),
            account.email
        );
    }
    Ok(())
}

fn fetch_calendars(
    mut fetch: impl FnMut(&str) -> Result<Value, String>,
) -> Result<Vec<Calendar>, String> {
    let mut page_token: Option<String> = None;
    let mut calendars = Vec::new();
    let mut seen_pages = Vec::new();
    loop {
        let mut endpoint =
            url::Url::parse("https://www.googleapis.com/calendar/v3/users/me/calendarList")
                .unwrap();
        endpoint
            .query_pairs_mut()
            .append_pair("maxResults", "250")
            .append_pair("showHidden", "true");
        if let Some(page) = &page_token {
            endpoint.query_pairs_mut().append_pair("pageToken", page);
        }
        let document = fetch(endpoint.as_str())?;
        let items = document
            .get("items")
            .and_then(Value::as_array)
            .ok_or("Google returned no calendar list.")?;
        for item in items {
            if item.get("deleted").and_then(Value::as_bool) == Some(true) {
                continue;
            }
            let id = item
                .get("id")
                .and_then(Value::as_str)
                .ok_or("Google returned a calendar without an ID.")?;
            let name = item
                .get("summaryOverride")
                .or_else(|| item.get("summary"))
                .and_then(Value::as_str)
                .unwrap_or(id);
            let role = item
                .get("accessRole")
                .and_then(Value::as_str)
                .unwrap_or("reader");
            if id.is_empty() {
                return Err("Google returned an empty calendar ID.".to_owned());
            }
            calendars.push(Calendar {
                id: id.to_owned(),
                name: name.to_owned(),
                read_only: !matches!(role, "owner" | "writer" | "writerWithoutPrivateAccess"),
            });
        }
        page_token = document
            .get("nextPageToken")
            .and_then(Value::as_str)
            .map(str::to_owned);
        if page_token.is_none() {
            break;
        }
        if seen_pages.contains(&page_token) {
            return Err("Google repeated a calendar-list page token.".to_owned());
        }
        seen_pages.push(page_token.clone());
    }
    Ok(calendars)
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
    fallback: &str,
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
        .unwrap_or_else(|| fallback.to_owned())
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

fn add_calendars(prefs: &mut Prefs, existing: &Existing, account: &Account, identity: &str) {
    let mut calendars = account.calendars.clone();
    for id in &account.calendar_ids {
        if !calendars.iter().any(|calendar| calendar.id == *id) {
            calendars.push(Calendar {
                id: id.clone(),
                name: id.clone(),
                read_only: false,
            });
        }
    }
    let mut seen: Vec<&str> = Vec::new();
    for discovered in &calendars {
        let calendar_id = discovered.id.as_str();
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
                        == wanted.trim_end_matches('/')
                    && existing
                        .get(&key.replace(".uri", ".username"))
                        .and_then(Value::as_str)
                        .is_some_and(|email| email.eq_ignore_ascii_case(&account.email));
                same.then(|| key.split('.').nth(2).map(str::to_owned))
                    .flatten()
            })
            .unwrap_or_else(|| {
                Uuid::new_v5(
                    &Uuid::NAMESPACE_URL,
                    format!("google-calendar:{}:{calendar_id}", account.email).as_bytes(),
                )
                .to_string()
            });
        let prefix = format!("calendar.registry.{calendar}.");
        let entries = [
            ("type", json!("caldav")),
            ("uri", json!(uri)),
            ("name", json!(discovered.name)),
            ("username", json!(account.email)),
            ("imip.identity.key", json!(identity)),
            ("disabled", json!(false)),
            ("readOnly", json!(discovered.read_only)),
            ("cache.enabled", json!(true)),
        ];
        for (suffix, value) in entries {
            prefs.insert(format!("{prefix}{suffix}"), value);
        }
        append_item(prefs, existing, "calendar.list.sortOrder", &calendar, ' ');
    }
}

fn build_account_prefs(existing: &Existing, account_config: &Account, fallback_id: &str) -> Prefs {
    let email = &account_config.email;
    let identity_default = fallback_id.to_owned();
    let account_default = fallback_id.to_owned();
    let server_default = fallback_id.to_owned();
    let smtp_default = fallback_id.to_owned();
    // Reuse a matching account left by Home Manager or manual setup.
    let identity = first_id(
        existing,
        "mail.identity.",
        ".useremail",
        &identity_default,
        |value| value.as_str() == Some(email.as_str()),
    );
    let account_id = first_id(
        existing,
        "mail.account.",
        ".identities",
        &account_default,
        |value| text_of(value).split(',').any(|item| item == identity),
    );
    let server = existing_or(
        existing,
        &format!("mail.account.{account_id}.server"),
        &server_default,
    );
    let smtp = existing_or(
        existing,
        &format!("mail.identity.{identity}.smtpServer"),
        &smtp_default,
    );
    let identities_key = format!("mail.account.{account_id}.identities");
    let real_name = account_config
        .real_name
        .as_deref()
        .filter(|name| !name.is_empty())
        .unwrap_or(email);
    let entries = [
        (
            identities_key.clone(),
            json!(existing_or(existing, &identities_key, &identity)),
        ),
        (format!("mail.account.{account_id}.server"), json!(server)),
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
        &account_id,
        ',',
    );
    append_item(&mut prefs, existing, "mail.smtpservers", &smtp, ',');
    prefs.insert(
        "mail.accountmanager.defaultaccount".to_owned(),
        json!(existing_or(
            existing,
            "mail.accountmanager.defaultaccount",
            &account_id
        )),
    );
    prefs.insert(
        "mail.smtp.defaultserver".to_owned(),
        json!(existing_or(existing, "mail.smtp.defaultserver", &smtp)),
    );
    add_calendars(&mut prefs, existing, account_config, &identity);
    prefs
}

fn build_prefs(existing: &Existing, accounts: &[Account]) -> Prefs {
    let mut prefs = Prefs::new();
    let mut current = existing.clone();
    for account in accounts {
        let fallback_id = format!(
            "dotdotsGoogle{}",
            Uuid::new_v5(
                &Uuid::NAMESPACE_URL,
                account.email.to_lowercase().as_bytes()
            )
            .simple()
        );
        for (key, value) in build_account_prefs(&current, account, &fallback_id) {
            current.insert(key.clone(), value.clone());
            prefs.insert(key, value);
        }
    }
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

fn configure(profile: &Path, accounts: &[Account]) -> Result<(), String> {
    // run() holds the POSIX profile lock; leftover marker files can survive a crash.
    let path = profile.join("prefs.js");
    if path.is_symlink() {
        return Err("prefs.js must be a writable profile file, not a symlink.".to_owned());
    }
    let original = match fs::read_to_string(&path) {
        Ok(text) => text,
        Err(error) if error.kind() == ErrorKind::NotFound => String::new(),
        Err(error) => return Err(format!("Cannot read {}: {error}", path.display())),
    };
    let prefs = build_prefs(&read_prefs(&original), accounts);
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

fn run(config_path: &Path, profile: &Path) -> Result<(), String> {
    let mut config = read_config(config_path)?;
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
    discover_calendars(&mut config)?;
    configure(profile, &config.accounts)
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
            "--config" | "--env" | "--profile" => {
                let value = inline
                    .or_else(|| arguments.next())
                    .ok_or_else(|| format!("{flag} needs a value."))?;
                if flag == "--config" || flag == "--env" {
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
    let config_dir = xdg("XDG_CONFIG_HOME", home.join(".config")).join("thunderbird");
    let configured_toml = config_dir.join("google.toml");
    let configured_env = config_dir.join("google.env");
    let private_config = home.join("Private/config.toml");
    let default_config = if private_config.exists() {
        private_config
    } else if configured_toml.exists() {
        configured_toml
    } else if configured_env.exists() {
        configured_env
    } else {
        home.join(".env")
    };
    let default_profile = home.join(".thunderbird/google");
    let outcome =
        parse_arguments(default_config, default_profile).and_then(|parsed| match parsed {
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

#[cfg(test)]
mod tests {
    use super::*;

    fn accounts() -> Vec<Account> {
        read_toml(
            Path::new("config.toml"),
            r#"
            [[thunderbird.accounts]]
            email = "one@example.com"
            real_name = "One, Example"
            [[thunderbird.accounts]]
            email = "two@example.com"
            real_name = "Two Example"
        "#,
        )
        .unwrap()
    }

    #[test]
    fn accounts_need_no_calendar_ids_and_keep_names_together() {
        let accounts = accounts();
        assert_eq!(accounts[0].real_name.as_deref(), Some("One, Example"));
        assert_eq!(accounts[1].email, "two@example.com");
        assert!(accounts
            .iter()
            .all(|account| account.calendar_ids.is_empty()));
    }

    #[test]
    fn discovery_follows_pages_and_includes_hidden_names_and_permissions() {
        let mut calls = 0;
        let calendars = fetch_calendars(|endpoint| {
            let url = url::Url::parse(endpoint).unwrap();
            let query: HashMap<_, _> = url.query_pairs().into_owned().collect();
            assert_eq!(query.get("showHidden").map(String::as_str), Some("true"));
            calls += 1;
            Ok(if calls == 1 {
                assert!(!query.contains_key("pageToken"));
                json!({"items": [{"id": "main@example.com", "summary": "Main", "accessRole": "owner"}], "nextPageToken": "next+/="})
            } else {
                assert_eq!(query.get("pageToken").map(String::as_str), Some("next+/="));
                json!({"items": [
                    {"id": "shared@example.com", "summary": "Shared", "summaryOverride": "My Shared", "hidden": true, "accessRole": "reader"},
                    {"id": "gone@example.com", "deleted": true}
                ]})
            })
        }).unwrap();
        assert_eq!(calls, 2);
        assert_eq!(calendars.len(), 2);
        assert!(!calendars[0].read_only);
        assert_eq!(calendars[1].name, "My Shared");
        assert!(calendars[1].read_only);
    }

    #[test]
    fn discovery_rejects_incomplete_data_and_repeated_pages() {
        assert!(fetch_calendars(|_| Ok(json!({"items": [{"summary": "No ID"}]}))).is_err());
        assert!(fetch_calendars(|_| Ok(json!({"items": [], "nextPageToken": "repeat"}))).is_err());
    }

    #[test]
    fn shared_calendar_accounts_remain_distinct_and_reruns_are_stable() {
        let mut accounts = accounts();
        for account in &mut accounts {
            account.calendars.push(Calendar {
                id: "shared@example.com".to_owned(),
                name: "Shared Calendar".to_owned(),
                read_only: true,
            });
        }
        let existing = Map::from_iter([("unrelated.preference".to_owned(), json!(true))]);
        let prefs = build_prefs(&existing, &accounts);
        assert_eq!(
            prefs
                .iter()
                .filter(|(key, _)| key.starts_with("calendar.registry.") && key.ends_with(".uri"))
                .count(),
            2
        );
        let identities: Vec<_> = prefs
            .iter()
            .filter(|(key, _)| key.starts_with("mail.identity.") && key.ends_with(".fullName"))
            .map(|(_, name)| name.as_str().unwrap())
            .collect();
        assert!(identities.contains(&"One, Example"));
        assert!(identities.contains(&"Two Example"));
        let mut updated = existing.clone();
        updated.extend(prefs.clone());
        assert_eq!(build_prefs(&updated, &accounts), prefs);
        accounts.reverse();
        assert_eq!(build_prefs(&updated, &accounts), prefs);
        assert_eq!(updated["unrelated.preference"], json!(true));
    }

    #[test]
    fn discovery_rejects_a_different_google_account() {
        assert!(
            check_account_email(&json!({"email": "other@example.com"}), "wanted@example.com")
                .is_err()
        );
        assert!(check_account_email(
            &json!({"email": "Wanted@example.com"}),
            "wanted@example.com"
        )
        .is_ok());
    }

    #[test]
    fn refresh_cache_is_private_and_replaced_atomically() {
        let directory =
            env::temp_dir().join(format!("thunderbird-oauth-test-{}", std::process::id()));
        fs::create_dir(&directory).unwrap();
        let path = directory.join("token.json");
        save_refresh_token(&path, "client", "old-test-refresh").unwrap();
        save_refresh_token(&path, "client", "new-test-refresh").unwrap();
        assert_eq!(
            fs::metadata(&path).unwrap().permissions().mode() & 0o777,
            0o600
        );
        assert_eq!(
            private_json(&path).unwrap()["refresh_token"],
            json!("new-test-refresh")
        );
        assert_eq!(fs::read_dir(&directory).unwrap().count(), 1);
        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn token_transport_preserves_oauth_errors_for_reauthorisation() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(5)))
                .unwrap();
            let mut reader = BufReader::new(&stream);
            let mut first = String::new();
            reader.read_line(&mut first).unwrap();
            assert!(first.starts_with("POST /token "));
            let mut length = 0;
            loop {
                let mut header = String::new();
                reader.read_line(&mut header).unwrap();
                if header == "\r\n" {
                    break;
                }
                if let Some(value) = header.to_lowercase().strip_prefix("content-length:") {
                    length = value.trim().parse().unwrap();
                }
            }
            let mut body = vec![0; length];
            reader.read_exact(&mut body).unwrap();
            let body = String::from_utf8(body).unwrap();
            assert!(body.contains("grant_type=refresh_token"));
            assert!(body.contains("client_secret=test-secret"));
            let reply = r#"{"error":"invalid_grant"}"#;
            write!(stream, "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{reply}", reply.len()).unwrap();
        });
        let client = BasicClient::new(
            ClientId::new("test-client".to_owned()),
            Some(ClientSecret::new("test-secret".to_owned())),
            AuthUrl::new("https://accounts.google.com/o/oauth2/v2/auth".to_owned()).unwrap(),
            Some(TokenUrl::new(format!("http://{address}/token")).unwrap()),
        )
        .set_auth_type(AuthType::RequestBody);
        let result = client
            .exchange_refresh_token(&RefreshToken::new("test-refresh".to_owned()))
            .request(token_http_client);
        assert!(
            matches!(result, Err(oauth2::RequestTokenError::ServerResponse(response))
            if response.error() == &oauth2::basic::BasicErrorResponseType::InvalidGrant)
        );
        server.join().unwrap();
    }

    #[test]
    fn oauth_callback_ignores_wrong_state_and_returns_matching_code() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let address = listener.local_addr().unwrap();
        let client = std::thread::spawn(move || {
            for state in ["wrong", "expected"] {
                let mut stream = std::net::TcpStream::connect(address).unwrap();
                write!(
                    stream,
                    "GET /?state={state}&code=valid-code HTTP/1.1\r\nHost: localhost\r\n\r\n"
                )
                .unwrap();
                let mut reply = String::new();
                stream.read_to_string(&mut reply).unwrap();
                assert!(reply.contains(if state == "wrong" {
                    "400 Bad Request"
                } else {
                    "200 OK"
                }));
            }
        });
        assert_eq!(receive_code(&listener, "expected").unwrap(), "valid-code");
        client.join().unwrap();
    }
}
