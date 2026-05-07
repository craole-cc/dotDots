#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! clap = { version = "4.5", features = ["derive"] }
//! miette = { version = "7", features = ["fancy"] }
//! regex = "1"
//! thiserror = "2"
//! ```

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use {
    clap::Parser,
    miette::{Diagnostic, Result},
    regex::Regex,
    std::{
        collections::BTreeMap,
        env,
        ffi::OsString,
        fs,
        path::{Path, PathBuf},
        process::{Command, Stdio},
    },
    thiserror::Error,
};

#[derive(Debug, Parser)]
#[command(
    name = "vr3n",
    about = "Print versions for common development commands.",
    disable_help_subcommand = true
)]
struct Cli {
    /// Print versions for all known commands found on PATH.
    #[arg(short = 'a', long = "all")]
    all: bool,

    /// List known command names and aliases.
    #[arg(short = 'l', long = "list")]
    list: bool,

    /// Print missing commands too.
    #[arg(short = 'm', long = "missing")]
    missing: bool,

    /// Always include command names in output.
    #[arg(short = 'n', long = "names")]
    names: bool,

    /// Commands to inspect.
    commands: Vec<String>,
}

#[derive(Debug, Error, Diagnostic)]
enum Error {
    #[error("unknown command: {0}")]
    #[diagnostic(help("Use --list to see known names and aliases."))]
    UnknownCommand(String),

    #[error("one or more commands were missing")]
    #[diagnostic(help("Use --missing to print missing commands in the output."))]
    MissingCommands,
}

#[derive(Debug, Clone, Copy)]
enum Mode {
    Version,
    Head,
    Custom(&'static [&'static str]),
}

#[derive(Debug, Clone, Copy)]
struct App {
    name: &'static str,
    cmd: Option<&'static str>,
    mode: Mode,
    aliases: &'static [&'static str],
}

impl App {
    const fn new(name: &'static str) -> Self {
        Self {
            name,
            cmd: None,
            mode: Mode::Version,
            aliases: &[],
        }
    }

    const fn head(name: &'static str) -> Self {
        Self {
            name,
            cmd: None,
            mode: Mode::Head,
            aliases: &[],
        }
    }

    const fn custom(name: &'static str, args: &'static [&'static str]) -> Self {
        Self {
            name,
            cmd: None,
            mode: Mode::Custom(args),
            aliases: &[],
        }
    }

    const fn aliases(name: &'static str, aliases: &'static [&'static str]) -> Self {
        Self {
            name,
            cmd: None,
            mode: Mode::Version,
            aliases,
        }
    }

    const fn cmd_aliases(
        name: &'static str,
        cmd: &'static str,
        aliases: &'static [&'static str],
    ) -> Self {
        Self {
            name,
            cmd: Some(cmd),
            mode: Mode::Version,
            aliases,
        }
    }
}

const APPS: &[App] = &[
    App::new("bat"),
    App::new("cargo"),
    App::head("curl"),
    App::head("deno"),
    App::new("direnv"),
    App::aliases("fd", &["fdfind"]),
    App::new("git"),
    App::new("gitui"),
    App::head("gum"),
    App::cmd_aliases("helix", "hx", &["hx"]),
    App::new("jq"),
    App::new("leptosfmt"),
    App::new("lsd"),
    App::custom("mise", &["version"]),
    App::new("nitch"),
    App::new("nix"),
    App::new("nixd"),
    App::new("node"),
    App::new("npm"),
    App::new("onefetch"),
    App::new("pnpm"),
    App::aliases("prettierd", &["prettier"]),
    App::aliases("python", &["python3"]),
    App::aliases("rg", &["ripgrep", "ripgrep-all"]),
    App::new("ruby"),
    App::new("rustc"),
    App::new("rustfmt"),
    App::new("rust-script"),
    App::new("sd"),
    App::new("sqlx"),
    App::new("tokei"),
    App::new("trashy"),
    App::new("treefmt"),
    App::new("wasm-bindgen"),
    App::new("wasm-pack"),
    App::new("wget"),
    App::new("xclip"),
    App::new("xsel"),
];

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

fn registry() -> BTreeMap<&'static str, &'static App> {
    let mut map = BTreeMap::new();

    for app in APPS {
        map.insert(app.name, app);

        for alias in app.aliases {
            map.insert(alias, app);
        }
    }

    map
}

fn list_known() {
    for app in APPS {
        if app.aliases.is_empty() {
            println!("{}", app.name);
        } else {
            println!("{} ({})", app.name, app.aliases.join(", "));
        }
    }
}

fn first_line(text: &str) -> &str {
    text.lines().next().unwrap_or(text).trim()
}

fn extract_version(raw: &str) -> String {
    let raw = first_line(raw);

    let cleaned = raw
        .strip_prefix("jq-")
        .unwrap_or(raw)
        .strip_prefix('v')
        .unwrap_or(raw);

    let re = Regex::new(r"\d+(\.\d+)+([-.+_~A-Za-z0-9]*)?").expect("valid version regex");

    re.find(cleaned)
        .map(|m| m.as_str().trim_start_matches('v').to_string())
        .unwrap_or_else(|| cleaned.to_string())
}

fn run_output(program: &Path, args: &[&str]) -> Option<String> {
    let output = Command::new(program)
        .args(args)
        .stderr(Stdio::piped())
        .output()
        .ok()?;

    let mut text = String::new();
    text.push_str(&String::from_utf8_lossy(&output.stdout));

    if text.trim().is_empty() {
        text.push_str(&String::from_utf8_lossy(&output.stderr));
    }

    if text.trim().is_empty() {
        return None;
    }

    Some(text)
}

fn version_args(mode: Mode) -> &'static [&'static str] {
    match mode {
        Mode::Version | Mode::Head => &["--version"],
        Mode::Custom(args) => args,
    }
}

fn command_candidates(app: &App) -> Vec<&'static str> {
    let mut candidates = Vec::new();

    candidates.push(app.cmd.unwrap_or(app.name));
    candidates.extend(app.aliases);

    candidates
}

fn version_for(app: &App) -> Option<(String, String)> {
    for command in command_candidates(app) {
        let Some(path) = find_cmd(command) else {
            continue;
        };

        let args = version_args(app.mode);
        let Some(output) = run_output(&path, args) else {
            continue;
        };

        return Some((command.to_string(), extract_version(&output)));
    }

    None
}

fn resolve_apps(cli: &Cli) -> Result<Vec<&'static App>> {
    if cli.all || cli.commands.is_empty() {
        return Ok(APPS.iter().collect());
    }

    let registry = registry();
    let mut apps = Vec::new();

    for command in &cli.commands {
        let Some(app) = registry.get(command.as_str()) else {
            return Err(Error::UnknownCommand(command.to_string()).into());
        };

        apps.push(*app);
    }

    Ok(apps)
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.list {
        list_known();
        return Ok(());
    }

    let apps = resolve_apps(&cli)?;
    let width = apps.iter().map(|app| app.name.len()).max().unwrap_or(0);
    let plain = !cli.all && !cli.missing && cli.commands.len() == 1;

    let mut failed = false;

    for app in apps {
        match version_for(app) {
            Some((_command, version)) => {
                if plain {
                    println!("{}", version);
                } else {
                    println!("{:<width$} {}", app.name, version, width = width);
                }
            }
            None if cli.missing => {
                if plain {
                    println!("missing");
                } else {
                    println!("{:<width$} missing", app.name, width = width);
                }

                failed = true;
            }
            None => {
                failed = true;
            }
        }
    }

    let explicit = !cli.all && !cli.commands.is_empty();

    if failed && explicit {
        return Err(Error::MissingCommands.into());
    }

    Ok(())
}
