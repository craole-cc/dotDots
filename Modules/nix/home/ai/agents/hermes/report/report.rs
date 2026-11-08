//! Report the declared Hermes team and verify on-disk profile directories.
//!
//! Usage: hermes-team-report [--check]
//!
//!   (no args)  Print {"profiles": [...]} to stdout.
//!   --check    Also verify every name in $HERMES_DECLARED_PROFILES has
//!              $HERMES_HOME/profiles/<name>/profile.yaml; exit 1 if not.

use std::{
    env::{args, var},
    fs::read_dir,
    io,
    path::{Path, PathBuf},
    process::ExitCode,
};

//~@ Library
//? Generic helpers, nothing Hermes-specific.

/// Quote a string as a JSON string literal, escaping everything the spec requires.
fn json_string(raw: &str) -> String {
    let mut out = String::with_capacity(raw.len() + 2);
    out.push('"');
    for ch in raw.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            //? Remaining control characters have no short escape.
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

//~@ Rules

/// Sorted names of the directories under `profiles_dir`.
/// A missing directory yields an empty list.
fn list_profiles(profiles_dir: &Path) -> io::Result<Vec<String>> {
    if !profiles_dir.is_dir() {
        return Ok(Vec::new());
    }

    let mut names = Vec::new();
    for entry in read_dir(profiles_dir)? {
        let path = entry?.path();

        //> Path::is_dir follows symlinks; DirEntry::file_type does not.
        //? Home-manager links are symlinks, so file_type().is_dir() would hide them.
        if !path.is_dir() {
            continue;
        }

        //? Non-UTF-8 names cannot be represented in the JSON output, so skip them.
        if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
            names.push(name.to_owned());
        }
    }
    names.sort();
    Ok(names)
}

fn profile_yaml_exists(profiles_dir: &Path, name: &str) -> bool {
    profiles_dir.join(name).join("profile.yaml").is_file()
}

fn render_listing(names: &[String]) -> String {
    let quoted: Vec<String> = names.iter().map(|name| json_string(name)).collect();
    format!("{{\"profiles\": [{}]}}", quoted.join(", "))
}

//~@ Execution
fn main() -> ExitCode {
    //> Parse arguments; anything unknown is a usage error.
    let mut check = false;
    for arg in args().skip(1) {
        match arg.as_str() {
            "--check" => check = true,
            other => {
                eprintln!("unknown argument: {other}");
                eprintln!("usage: hermes-team-report [--check]");
                return ExitCode::from(2);
            }
        }
    }

    let Ok(home) = var("HERMES_HOME").map(PathBuf::from) else {
        eprintln!("HERMES_HOME is not set");
        return ExitCode::from(2);
    };

    //> List profiles; report I/O failures instead of panicking.
    let profiles_dir = home.join("profiles");
    let names = match list_profiles(&profiles_dir) {
        Ok(names) => names,
        Err(error) => {
            eprintln!("cannot read {}: {error}", profiles_dir.display());
            return ExitCode::FAILURE;
        }
    };
    println!("{}", render_listing(&names));

    //> With --check, every declared profile must have a profile.yaml.
    if check {
        let declared = var("HERMES_DECLARED_PROFILES").unwrap_or_default();
        let missing: Vec<&str> = declared
            .split_whitespace()
            .filter(|name| !profile_yaml_exists(&profiles_dir, name))
            .collect();
        if !missing.is_empty() {
            eprintln!("missing profile.yaml for: {}", missing.join(", "));
            return ExitCode::FAILURE;
        }
    }

    ExitCode::SUCCESS
}

//~@ Simulation
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn escapes_json_specials() {
        assert_eq!(json_string("plain"), "\"plain\"");
        assert_eq!(json_string("a\"b"), "\"a\\\"b\"");
        assert_eq!(json_string("a\\b"), "\"a\\\\b\"");
        assert_eq!(json_string("a\nb"), "\"a\\nb\"");
        assert_eq!(json_string("a\u{1}b"), "\"a\\u0001b\"");
    }

    #[test]
    fn renders_empty_and_populated_listings() {
        assert_eq!(render_listing(&[]), "{\"profiles\": []}");
        let names = vec!["a".to_string(), "b\"c".to_string()];
        assert_eq!(
            render_listing(&names),
            "{\"profiles\": [\"a\", \"b\\\"c\"]}"
        );
    }

    #[test]
    fn missing_profiles_dir_is_empty() {
        let names = list_profiles(Path::new("/nonexistent/hermes/profiles")).unwrap();
        assert!(names.is_empty());
    }
}
