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
    path::{Path, PathBuf},
    process::ExitCode,
};

fn main() -> ExitCode {
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

    let home = match var("HERMES_HOME") {
        Ok(h) => PathBuf::from(h),
        Err(_) => {
            eprintln!("HERMES_HOME is not set");
            return ExitCode::from(2);
        }
    };

    let profiles_dir = home.join("profiles");
    let mut names: Vec<String> = Vec::new();
    if profiles_dir.is_dir() {
        for entry in read_dir(&profiles_dir).expect("read profiles dir") {
            let entry = entry.expect("read entry");
            if entry.file_type().expect("file type").is_dir() {
                if let Some(n) = entry.file_name().to_str() {
                    names.push(n.to_string());
                }
            }
        }
    }
    names.sort();

    let quoted: Vec<String> = names.iter().map(|n| format!("\"{n}\"")).collect();
    println!("{{\"profiles\": [{}]}}", quoted.join(", "));

    if check {
        let declared = var("HERMES_DECLARED_PROFILES").unwrap_or_default();
        let missing: Vec<&str> = declared
            .split_whitespace()
            .filter(|n| !profile_yaml_exists(&profiles_dir, n))
            .collect();
        if !missing.is_empty() {
            eprintln!("missing profile.yaml for: {}", missing.join(", "));
            return ExitCode::FAILURE;
        }
    }

    ExitCode::SUCCESS
}

fn profile_yaml_exists(profiles_dir: &Path, name: &str) -> bool {
    profiles_dir.join(name).join("profile.yaml").is_file()
}
