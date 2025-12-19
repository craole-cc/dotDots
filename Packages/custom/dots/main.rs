//! dots-cli - Single binary for NixOS configuration management
//!
//! ```cargo
//! [package]
//! name = "dots-cli"
//! version = "0.1.0"
//! edition = "2021"
//!
//! [dependencies]
//! clap = { version = "4.0", features = ["derive", "cargo"] }
//! anyhow = "1.0"
//! serde_json = "1.0"
//! colored = "2.0"
//! arboard = "3.2"  # Cross-platform clipboard
//! ```

use anyhow::{Context, Result};
use arboard::Clipboard;
use clap::{Parser, Subcommand};
use colored::*;
use std::env;
use std::process::Command;

#[derive(Parser)]
#[command(name = "dots", about = "NixOS Configuration Management", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// List all configured hosts
    Hosts,

    /// Show detailed host information
    Info {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show rebuild command
    Rebuild {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show test command
    Test {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show boot command
    Boot {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show dry-build command
    Dry {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show flake update command
    Update,

    /// Show garbage collection command
    Clean,

    /// List all available commands
    List,

    /// Show help
    Help,
}

/// Get current host name from environment
fn get_current_host() -> String {
    env::var("HOST_NAME").unwrap_or_else(|_| "QBX".to_string())
}

/// Get current system from environment
fn get_current_system() -> String {
    env::var("HOST_PLATFORM").unwrap_or_else(|_| "x86_64-linux".to_string())
}

/// Copy text to clipboard with cross-platform support
fn copy_to_clipboard(text: &str) -> Result<()> {
    let mut clipboard = Clipboard::new().context("Failed to initialize clipboard")?;
    clipboard
        .set_text(text)
        .context("Failed to copy to clipboard")?;
    Ok(())
}

/// Execute nix eval command and return JSON
fn nix_eval(expr: &str) -> Result<serde_json::Value> {
    let output = Command::new("nix")
        .args(["eval", "--impure", "--expr", expr, "--json"])
        .env("NIX_CONFIG", "experimental-features = nix-command flakes")
        .output()
        .context("Failed to execute nix eval")?;

    if output.status.success() {
        let json: serde_json::Value =
            serde_json::from_slice(&output.stdout).context("Failed to parse JSON output")?;
        Ok(json)
    } else {
        anyhow::bail!("Nix error: {}", String::from_utf8_lossy(&output.stderr));
    }
}

/// List all configured hosts
fn list_hosts() -> Result<()> {
    let json =
        nix_eval("builtins.attrNames (builtins.getFlake (toString ./.)).nixosConfigurations")?;

    if let Some(hosts) = json.as_array() {
        println!("{}", "Available hosts:".bold().cyan());
        for host in hosts {
            if let Some(host_str) = host.as_str() {
                println!("  • {}", host_str.green().bold());
            }
        }
    } else {
        println!("{}", "No hosts found".yellow());
    }
    Ok(())
}

/// Show host information
fn show_host_info(host: Option<String>) -> Result<()> {
    let host_name = host.unwrap_or_else(get_current_host);

    // Escape single quotes in host name
    let host_escaped = host_name.replace("'", "'\\''");

    let expr = format!(
        r#"
        let
          flake = builtins.getFlake (toString ./.);
          hostConfig = flake.nixosConfigurations."{}";
        in {{
          hostname = hostConfig.config.networking.hostName;
          system = hostConfig.config.nixpkgs.hostPlatform.system;
          kernel = hostConfig.config.boot.kernelPackages.kernel.version;
          stateVersion = hostConfig.config.system.stateVersion;
          desktop = (
            if hostConfig.config.services.desktopManager.plasma6.enable or false then "plasma"
            else if hostConfig.config.services.desktopManager.gnome.enable or false then "gnome"
            else if hostConfig.config.services.desktopManager.cosmic.enable or false then "cosmic"
            else "none"
          );
        }}
        "#,
        host_escaped
    );

    match nix_eval(&expr) {
        Ok(info) => {
            println!(
                "{} {}",
                "Host info for:".bold().cyan(),
                host_name.green().bold()
            );
            println!("{}", serde_json::to_string_pretty(&info)?);
            Ok(())
        }
        Err(_) => {
            println!("{} {}", "Error loading host:".red(), host_name);
            println!("{}", "Available hosts:".yellow());
            list_hosts()?;
            Ok(())
        }
    }
}

/// Generate and display a command, optionally copying to clipboard
fn show_command(command: &str, copy_to_clip: bool) {
    println!("{}", command.bright_white());

    if copy_to_clip {
        match copy_to_clipboard(command) {
            Ok(_) => println!("{}", "✓ Copied to clipboard".green()),
            Err(e) => println!("{} {}", "⚠ Could not copy to clipboard:".yellow(), e),
        }
    }
}

/// Show welcome/help message
fn show_help() {
    let host = get_current_host();
    let system = get_current_system();

    println!("{}", "🎯 NixOS Configuration REPL".bold().cyan());
    println!("{}\n", "=".repeat(28).dimmed());

    println!("{} {}", "Current host:".bold().yellow(), host.green());
    println!("{} {}\n", "System:".bold().yellow(), system.blue());

    println!("{}", "Available commands:".bold().magenta());
    println!(
        "  {} hosts            - List all configured hosts",
        "dots".cyan()
    );
    println!(
        "  {} info [host]      - Show host information",
        "dots".cyan()
    );
    println!(
        "  {} rebuild [host]   - Show rebuild command (copies to clipboard)",
        "dots".cyan()
    );
    println!(
        "  {} test [host]      - Show test command (copies to clipboard)",
        "dots".cyan()
    );
    println!(
        "  {} boot [host]      - Show boot command (copies to clipboard)",
        "dots".cyan()
    );
    println!(
        "  {} dry [host]       - Show dry-build command (copies to clipboard)",
        "dots".cyan()
    );
    println!(
        "  {} update           - Show flake update command (copies to clipboard)",
        "dots".cyan()
    );
    println!(
        "  {} clean            - Show garbage collection command (copies to clipboard)",
        "dots".cyan()
    );
    println!("  {} list             - List all commands", "dots".cyan());
    println!("  {} help             - Show this help", "dots".cyan());
    println!();

    println!("{}", "Quick usage:".bold().magenta());
    println!("  Most commands accept an optional host argument.");
    println!("  Default host: {}", host.green());
    println!();
}

fn main() -> Result<()> {
    let args = Cli::parse();

    match args.command {
        Commands::Hosts => list_hosts(),

        Commands::Info { host } => show_host_info(host),

        Commands::Rebuild { host } => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild switch --flake .#{}", host_name);
            show_command(&command, true);
            Ok(())
        }

        Commands::Test { host } => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild test --flake .#{}", host_name);
            show_command(&command, true);
            Ok(())
        }

        Commands::Boot { host } => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild boot --flake .#{}", host_name);
            show_command(&command, true);
            Ok(())
        }

        Commands::Dry { host } => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild dry-build --flake .#{}", host_name);
            show_command(&command, true);
            Ok(())
        }

        Commands::Update => {
            let command = "nix flake update";
            show_command(command, true);
            Ok(())
        }

        Commands::Clean => {
            let command = "sudo nix-collect-garbage -d";
            show_command(command, true);
            Ok(())
        }

        Commands::List => {
            println!("{}", "Available commands:".bold().cyan());
            println!(
                "  {} {}            - List all hosts",
                "dots".blue(),
                "hosts".green()
            );
            println!(
                "  {} {}      - Show host info",
                "dots".blue(),
                "info [host]".green()
            );
            println!(
                "  {} {}   - Rebuild host",
                "dots".blue(),
                "rebuild [host]".green()
            );
            println!(
                "  {} {}      - Test host",
                "dots".blue(),
                "test [host]".green()
            );
            println!(
                "  {} {}      - Boot host",
                "dots".blue(),
                "boot [host]".green()
            );
            println!(
                "  {} {}       - Dry build",
                "dots".blue(),
                "dry [host]".green()
            );
            println!(
                "  {} {}           - Update flake",
                "dots".blue(),
                "update".green()
            );
            println!(
                "  {} {}            - Clean garbage",
                "dots".blue(),
                "clean".green()
            );
            println!(
                "  {} {}             - List commands",
                "dots".blue(),
                "list".green()
            );
            println!(
                "  {} {}             - Show help",
                "dots".blue(),
                "help".green()
            );
            println!();
            println!(
                "{}",
                "Commands with [host] accept an optional host name.".dimmed()
            );
            println!("{}", "Default host:".dimmed(),);
            println!("  {}", get_current_host().green());
            Ok(())
        }

        Commands::Help => {
            show_help();
            Ok(())
        }
    }
}
