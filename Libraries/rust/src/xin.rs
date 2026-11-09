#!/usr/bin/env rust-script
//! ```cargo
//! [package]
//! edition = "2024"
//! ```
//! Nix operations with nh where supported and direct Nix access for scoped REPLs.

use std::{
    env,
    ffi::OsStr,
    os::unix::{fs::PermissionsExt, process::ExitStatusExt},
    path::PathBuf,
    process::Command,
};

const HELP: &str = "xin — Nix configuration helper

Usage: xin <ACTION> [OPTIONS] [-- EXTRA_ARGS...]

Actions (choose one):
  --check               Check the flake with tracing
  --clean               Run nh clean all (Nix store GC if nh is unavailable)
  --update [INPUT ...]  Update all inputs, or only the named inputs
  --repl                Open the flake REPL
  --repl-home           Open the current host/user Home Manager config
  --repl-core           Open the current host NixOS module (config/options/_module)
  --switch              Build and activate the NixOS configuration
  --build               Build without activation
  --boot                Build for the next boot
  --test                Activate without making the configuration the boot default

Options:
  --flake PATH          Checkout (default: DOTS, NH_FLAKE, then current directory)
  --host HOST           Host (default: hostname)
  --user USER           Home Manager user (default: USER)
  --no-trace            Disable --show-trace
  --dry-run             Print the command without running it
  -h, --help            Show this help

Examples:
  xin --update hermes       # Includes hermesRelease automatically
  xin --check --no-trace
  xin --repl-home
  xin --build -- --option keep-going true

Updates do not build, activate, commit, or push. Use xin --switch or nhs to apply.
";

#[derive(Clone, Copy, Debug, PartialEq)]
enum Action {
    Check,
    Clean,
    Update,
    Repl,
    ReplHome,
    ReplCore,
    Switch,
    Build,
    Boot,
    Test,
}

#[derive(Debug)]
struct Options {
    action: Action,
    flake: String,
    host: Option<String>,
    user: Option<String>,
    trace: bool,
    dry_run: bool,
    inputs: Vec<String>,
    extra: Vec<String>,
}

fn parse(args: Vec<String>) -> Result<Options, String> {
    let mut action = None;
    let mut options = Options {
        action: Action::Check,
        flake: env::var("DOTS")
            .or_else(|_| env::var("NH_FLAKE"))
            .unwrap_or_else(|_| ".".into()),
        host: None,
        user: None,
        trace: true,
        dry_run: false,
        inputs: vec![],
        extra: vec![],
    };
    let mut args = args.into_iter();
    while let Some(arg) = args.next() {
        let selected = match arg.as_str() {
            "--check" => Some(Action::Check),
            "--clean" => Some(Action::Clean),
            "--update" => Some(Action::Update),
            "--repl" => Some(Action::Repl),
            "--repl-home" => Some(Action::ReplHome),
            "--repl-core" => Some(Action::ReplCore),
            "--switch" => Some(Action::Switch),
            "--build" => Some(Action::Build),
            "--boot" => Some(Action::Boot),
            "--test" => Some(Action::Test),
            "--no-trace" => {
                options.trace = false;
                None
            }
            "--dry-run" => {
                options.dry_run = true;
                None
            }
            "--flake" | "--host" | "--user" => {
                let value = args
                    .next()
                    .filter(|value| !value.is_empty() && !value.starts_with('-'))
                    .ok_or_else(|| format!("{arg} requires a value"))?;
                match arg.as_str() {
                    "--flake" => options.flake = value,
                    "--host" => options.host = Some(value),
                    _ => options.user = Some(value),
                }
                None
            }
            "--" => {
                options.extra.extend(args);
                break;
            }
            _ if !arg.starts_with('-') && action == Some(Action::Update) => {
                options.inputs.push(arg);
                None
            }
            _ => {
                return Err(format!(
                    "Unknown argument: {arg}\nUse xin --help for usage."
                ));
            }
        };
        if let Some(selected) = selected {
            if action.replace(selected).is_some() {
                return Err("Choose only one action per invocation".into());
            }
        }
    }
    options.action = action.ok_or("Choose an action; use xin --help for usage.")?;
    if options.action == Action::Update
        && options.inputs.iter().any(|v| v == "hermes")
        && !options.inputs.iter().any(|v| v == "hermesRelease")
    {
        options.inputs.push("hermesRelease".into());
    }
    Ok(options)
}

fn available(program: &str) -> bool {
    env::var_os("PATH")
        .map(|path| {
            env::split_paths(&path).any(|dir| {
                let path = dir.join(program);
                path.is_file()
                    && path
                        .metadata()
                        .map(|meta| meta.permissions().mode() & 0o111 != 0)
                        .unwrap_or(false)
            })
        })
        .unwrap_or(false)
}

fn hostname() -> Result<String, String> {
    let output = Command::new("hostname")
        .output()
        .map_err(|error| format!("hostname: {error}"))?;
    if !output.status.success() {
        return Err("hostname failed; use --host HOST".into());
    }
    let host = String::from_utf8(output.stdout)
        .map_err(|error| error.to_string())?
        .trim()
        .to_owned();
    if host.is_empty() {
        return Err("hostname returned an empty name; use --host HOST".into());
    }
    Ok(host)
}

// Attribute-path quoting is Nix syntax, independent of shell argument quoting.
fn attribute(value: &str) -> String {
    format!(
        "\"{}\"",
        value
            .replace('\\', "\\\\")
            .replace('"', "\\\"")
            .replace("${", "\\${")
            .replace('\n', "\\n")
            .replace('\r', "\\r")
            .replace('\t', "\\t")
    )
}

fn plan(options: &Options, nh: bool) -> Result<(String, Vec<String>), String> {
    let mut program = "nix".to_owned();
    let mut args: Vec<String> = vec![];
    match options.action {
        Action::Check => args.extend(["flake".into(), "check".into(), options.flake.clone()]),
        Action::Update => {
            args.extend([
                "flake".into(),
                "update".into(),
                "--flake".into(),
                options.flake.clone(),
            ]);
            args.extend(options.inputs.clone());
        }
        Action::Clean => {
            if nh {
                program = "nh".into();
                args.extend(["clean".into(), "all".into()]);
            } else {
                args.extend(["store".into(), "gc".into()]);
            }
        }
        Action::Repl | Action::ReplHome | Action::ReplCore => {
            let mut target = options.flake.clone();
            if options.action != Action::Repl {
                let host = options.host.clone().map(Ok).unwrap_or_else(hostname)?;
                target.push_str(&format!("#nixosConfigurations.{}", attribute(&host)));
                if options.action == Action::ReplHome {
                    let user = options
                        .user
                        .clone()
                        .or_else(|| env::var("USER").ok())
                        .filter(|v| !v.is_empty())
                        .ok_or("USER is unset; use --user USER")?;
                    target.push_str(&format!(".config.home-manager.users.{}", attribute(&user)));
                }
            }
            args.extend(["repl".into(), target]);
        }
        action => {
            let operation = match action {
                Action::Switch => "switch",
                Action::Build => "build",
                Action::Boot => "boot",
                Action::Test => "test",
                _ => unreachable!(),
            };
            let host = options.host.clone().map(Ok).unwrap_or_else(hostname)?;
            if nh {
                program = "nh".into();
                args.extend([
                    "os".into(),
                    operation.into(),
                    options.flake.clone(),
                    "--hostname".into(),
                    host,
                ]);
                if options.trace || !options.extra.is_empty() {
                    args.push("--".into());
                }
            } else {
                if !available("nixos-rebuild") {
                    return Err("Neither nh nor nixos-rebuild is available".into());
                }
                program = "nixos-rebuild".into();
                args.extend([
                    operation.into(),
                    "--flake".into(),
                    format!("{}#{}", options.flake, attribute(&host)),
                ]);
                if action != Action::Build {
                    args.push("--sudo".into());
                }
            }
        }
    }
    if options.trace && options.action != Action::Clean {
        args.push("--show-trace".into());
    }
    args.extend(options.extra.clone());
    Ok((program, args))
}

fn quote(value: &OsStr) -> String {
    format!("'{}'", value.to_string_lossy().replace('\'', "'\\''"))
}

fn run() -> Result<i32, String> {
    let args: Vec<String> = env::args().skip(1).collect();
    if args
        .iter()
        .take_while(|arg| arg.as_str() != "--")
        .any(|arg| arg == "--help" || arg == "-h")
        || args.is_empty()
    {
        print!("{HELP}");
        return Ok(0);
    }
    let mut options = parse(args)?;
    let flake = PathBuf::from(&options.flake);
    if options.action != Action::Clean && !flake.join("flake.nix").is_file() {
        return Err(format!("No flake.nix in {}", flake.display()));
    }
    if options.action != Action::Clean {
        options.flake = flake
            .canonicalize()
            .map_err(|error| error.to_string())?
            .to_string_lossy()
            .into_owned();
    }
    let nh = available("nh");
    let (program, args) = plan(&options, nh)?;
    eprintln!(
        "{} {}",
        quote(OsStr::new(&program)),
        args.iter()
            .map(|arg| quote(OsStr::new(arg)))
            .collect::<Vec<_>>()
            .join(" ")
    );
    if options.dry_run {
        return Ok(0);
    }
    if !available(&program) {
        return Err(format!("Required command is unavailable: {program}"));
    }
    if options.action == Action::Clean && !nh {
        eprintln!("nh is unavailable; collecting unreferenced store paths with nix store gc.");
    }
    let status = Command::new(program)
        .args(args)
        .status()
        .map_err(|error| error.to_string())?;
    Ok(status
        .code()
        .unwrap_or_else(|| 128 + status.signal().unwrap_or(1)))
}

fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err(error) => {
            eprintln!("xin: {error}");
            std::process::exit(2);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    fn options(args: &[&str]) -> Options {
        parse(args.iter().map(|v| (*v).into()).collect()).unwrap()
    }
    #[test]
    fn updates_pair_hermes_without_duplicates() {
        assert_eq!(
            options(&["--update", "hermes", "buufIcons"]).inputs,
            ["hermes", "buufIcons", "hermesRelease"]
        );
        assert_eq!(
            options(&["--update", "hermes", "hermesRelease"])
                .inputs
                .len(),
            2
        );
        assert!(options(&["--update"]).inputs.is_empty());
    }
    #[test]
    fn rejects_conflicting_actions_and_missing_values() {
        for args in [
            vec!["--check", "--clean"],
            vec!["--flake"],
            vec!["--check", "surprise"],
        ] {
            assert!(parse(args.into_iter().map(String::from).collect()).is_err());
        }
    }
    #[test]
    fn home_repl_uses_quoted_host_and_user_attributes() {
        let options = options(&[
            "--repl-home",
            "--host",
            "my.host",
            "--user",
            "a.b",
            "--flake",
            "/a b",
        ]);
        let (program, args) = plan(&options, true).unwrap();
        assert_eq!(program, "nix");
        assert_eq!(
            args,
            [
                "repl",
                "/a b#nixosConfigurations.\"my.host\".config.home-manager.users.\"a.b\"",
                "--show-trace"
            ]
        );
    }
    #[test]
    fn nh_build_forwards_trace_and_nix_arguments_after_separator() {
        let options = options(&["--build", "--host", "Victus", "--", "--keep-going"]);
        let (program, args) = plan(&options, true).unwrap();
        assert_eq!(program, "nh");
        assert_eq!(
            &args[args.len() - 3..],
            ["--", "--show-trace", "--keep-going"]
        );
    }
    #[test]
    fn no_trace_applies_to_checks_and_repls() {
        for action in ["--check", "--repl", "--repl-core"] {
            let options = options(&[action, "--no-trace", "--host", "Victus"]);
            assert!(
                !plan(&options, true)
                    .unwrap()
                    .1
                    .contains(&"--show-trace".into())
            );
        }
    }
}
