//! Validate a Hermes profile name against upstream's rules.
//!
//! Rules (mirrored from the pinned flake.lock revision):
//!   - 1..=64 characters
//!   - first character: [a-z0-9]
//!   - remaining characters: [a-z0-9_-]
//!   - not the reserved name "default"
//!
//! Exit codes:
//!   0  all names valid
//!   1  one or more names invalid (stderr lists them)
//!   2  usage error
//!
//! No external crates: compiles in well under a second and has no
//! dependency on the Hermes Python venv.
use std::{env::args, process::ExitCode};

const MAX_LEN: usize = 64;
const RESERVED: &str = "default";

fn is_valid(name: &str) -> Result<(), &'static str> {
    if name.is_empty() {
        return Err("name is empty");
    }
    if name.len() > MAX_LEN {
        return Err("name exceeds 64 characters");
    }
    if name == RESERVED {
        return Err("'default' is reserved; configure the default profile via settings");
    }
    let mut chars = name.chars();
    let first = chars.next().expect("non-empty checked above");
    if !first.is_ascii_lowercase() && !first.is_ascii_digit() {
        return Err("first character must be [a-z0-9]");
    }
    for c in chars {
        if !(c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-') {
            return Err("characters must be [a-z0-9_-]");
        }
    }
    Ok(())
}

fn main() -> ExitCode {
    let names: Vec<String> = args().skip(1).collect();
    if names.is_empty() {
        eprintln!("usage: hermes-profile-validate NAME [NAME...]");
        return ExitCode::from(2);
    }

    let mut failed = false;
    for name in &names {
        if let Err(reason) = is_valid(name) {
            eprintln!("invalid Hermes profile name '{name}': {reason}");
            failed = true;
        }
    }

    if failed {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}

#[cfg(test)]
mod tests {
    use super::is_valid;

    #[test]
    fn accepts_valid() {
        for n in ["planner", "reviewer-2", "agent_1", "a", "0"] {
            assert!(is_valid(n).is_ok(), "{n} should be valid");
        }
    }

    #[test]
    fn rejects_invalid() {
        for n in [
            "",
            "Default",
            "default",
            "Planner",
            "-planner",
            "_planner",
            "with space",
            "with/slash",
        ] {
            assert!(is_valid(n).is_err(), "{n} should be invalid");
        }
    }

    #[test]
    fn rejects_too_long() {
        assert!(is_valid(&"a".repeat(65)).is_err());
    }
}
