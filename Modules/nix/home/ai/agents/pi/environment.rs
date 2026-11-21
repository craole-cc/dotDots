// cargo-deps: adotenv="=1.2.0", glob="=0.3.4"
//!
//! Load ordered dotenv sources and replace this process with Pi.
//!
//! Values use adotenv's python-dotenv dialect without interpolation. A bare
//! key does not override an inherited or earlier value; an explicit empty
//! assignment does.

use std::{
    collections::HashMap, env, ffi::OsString, os::unix::process::CommandExt, path::PathBuf,
    process::Command,
};

use adotenv::{parse_with, Dialect};

fn expand_home(pattern: &str) -> String {
    if pattern == "~" || pattern.starts_with("~/") {
        if let Some(home) = env::var_os("HOME") {
            let suffix = pattern.strip_prefix('~').unwrap_or_default();
            return format!("{}{}", PathBuf::from(home).display(), suffix);
        }
    }
    pattern.to_owned()
}

fn source_files(pattern: &str) -> Vec<PathBuf> {
    let expanded = expand_home(pattern);
    let mut matches: Vec<PathBuf> = match glob::glob(&expanded) {
        Ok(paths) => paths.filter_map(Result::ok).collect(),
        Err(_) => Vec::new(),
    };
    matches.sort();
    matches
}

fn load_values(sources: &[String]) -> HashMap<OsString, OsString> {
    let mut values: HashMap<OsString, OsString> = env::vars_os().collect();

    for source in sources {
        for path in source_files(source) {
            if !path.is_file() {
                continue;
            }

            let Ok(contents) = std::fs::read_to_string(&path) else {
                continue;
            };
            let (document, _diagnostics) = parse_with(&contents, Dialect::PYTHON_DOTENV);

            for entry in document.entries() {
                if let Some(value) = entry.value() {
                    values.insert(entry.key().into(), value.into());
                }
            }
        }
    }

    values
}

fn run() -> Result<(), String> {
    let mut arguments = env::args_os().skip(1);
    let mut sources = Vec::new();
    let command = loop {
        match arguments.next() {
            Some(argument) if argument == "--" => break arguments,
            Some(argument) => sources.push(
                argument
                    .into_string()
                    .map_err(|_| "credential source path is not valid UTF-8".to_owned())?,
            ),
            None => return Err("missing -- separator and Pi command".to_owned()),
        }
    };

    let mut command = command;
    let executable = command
        .next()
        .ok_or_else(|| "missing Pi command after --".to_owned())?;
    let mut process = Command::new(executable);
    process.args(command).envs(load_values(&sources));

    // A successful exec replaces this launcher; on failure only the error is
    // reported, never the inherited or loaded credential values.
    Err(process.exec().to_string())
}

fn main() {
    if let Err(error) = run() {
        eprintln!("pi credential launcher: {error}");
        std::process::exit(1);
    }
}
