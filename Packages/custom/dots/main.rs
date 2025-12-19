#!/usr/bin/env -S rust-script
//! ```cargo
//! [package]
//! name = "dotdots-cli"
//! version = "0.1.0"
//! edition = "2021"
//!
//! [dependencies]
//! clap = { version = "4.0", features = ["derive", "cargo"] }
//! anyhow = "1.0"
//! serde_json = "1.0"
//! colored = "2.0"
//! arboard = "3.2"
//! ```

use anyhow::{Context, Result};
use arboard::Clipboard;
use clap::{Parser, Subcommand};
use colored::*;
use std::env;
use std::process::{Command, Stdio};

#[derive(Parser)]
#[command(name = "dotDots", about = "NixOS Configuration Management", long_about = None)]
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

    /// Show rebuild command (add --execute to run it)
    Rebuild {
        /// Host name (default: current host)
        host: Option<String>,

        /// Execute the command immediately
        #[arg(long)]
        execute: bool,
    },

    /// Show test command (add --execute to run it)
    Test {
        /// Host name (default: current host)
        host: Option<String>,

        /// Execute the command immediately
        #[arg(long)]
        execute: bool,
    },

    /// Show boot command (add --execute to run it)
    Boot {
        /// Host name (default: current host)
        host: Option<String>,

        /// Execute the command immediately
        #[arg(long)]
        execute: bool,
    },

    /// Show dry-build command
    Dry {
        /// Host name (default: current host)
        host: Option<String>,
    },

    /// Show flake update command (add --execute to run it)
    Update {
        /// Execute the command immediately
        #[arg(long)]
        execute: bool,
    },

    /// Show garbage collection command (add --execute to run it)
    Clean {
        /// Execute the command immediately
        #[arg(long)]
        execute: bool,
    },

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

/// Execute a shell command and return output
fn execute_command(cmd: &str) -> Result<()> {
    println!("{}", "Executing:".yellow());
    println!("  {}", cmd.cyan());
    println!();

    let status = Command::new("sh")
        .arg("-c")
        .arg(cmd)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .context("Failed to execute command")?;

    if status.success() {
        println!("\n{}", "✓ Command executed successfully".green());
    } else {
        println!("\n{}", "✗ Command failed".red());
    }

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

/// Generate and display a command, optionally copying to clipboard and executing
fn handle_command(base_cmd: &str, host: Option<String>, execute: bool) -> Result<()> {
    let host_name = host.unwrap_or_else(get_current_host);
    let command = if base_cmd.contains("{}") {
        base_cmd.replace("{}", &host_name)
    } else {
        base_cmd.to_string()
    };

    println!("{}", command.bright_white());

    // Try to copy to clipboard
    match copy_to_clipboard(&command) {
        Ok(_) => println!("{}", "✓ Copied to clipboard".green()),
        Err(e) => println!("{} {}", "⚠ Could not copy to clipboard:".yellow(), e),
    }

    // Execute if requested
    if execute {
        println!();
        execute_command(&command)?;
    }

    Ok(())
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
        "dotDots".cyan()
    );
    println!(
        "  {} info [host]      - Show host information",
        "dotDots".cyan()
    );
    println!(
        "  {} rebuild [host]   - Show rebuild command",
        "dotDots".cyan()
    );
    println!(
        "  {} test [host]      - Show test command",
        "dotDots".cyan()
    );
    println!(
        "  {} boot [host]      - Show boot command",
        "dotDots".cyan()
    );
    println!(
        "  {} dry [host]       - Show dry-build command",
        "dotDots".cyan()
    );
    println!(
        "  {} update           - Show flake update command",
        "dotDots".cyan()
    );
    println!(
        "  {} clean            - Show garbage collection command",
        "dotDots".cyan()
    );
    println!(
        "  {} list             - List all commands",
        "dotDots".cyan()
    );
    println!("  {} help             - Show this help", "dotDots".cyan());
    println!();

    println!("{}", "Options:".bold().magenta());
    println!("  Add --execute to any command to run it immediately");
    println!("  Add --execute to automatically copy to clipboard");
    println!();

    println!("{}", "Quick usage:".bold().magenta());
    println!("  dotDots rebuild QBX            # Show command");
    println!("  dotDots rebuild QBX --execute  # Run command");
    println!("  dotDots update --execute       # Update flake");
    println!();
}

fn main() -> Result<()> {
    let args = Cli::parse();

    match args.command {
        Commands::Hosts => list_hosts(),

        Commands::Info { host } => show_host_info(host),

        Commands::Rebuild { host, execute } => {
            handle_command("sudo nixos-rebuild switch --flake .#{}", host, execute)
        }

        Commands::Test { host, execute } => {
            handle_command("sudo nixos-rebuild test --flake .#{}", host, execute)
        }

        Commands::Boot { host, execute } => {
            handle_command("sudo nixos-rebuild boot --flake .#{}", host, execute)
        }

        Commands::Dry { host } => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild dry-build --flake .#{}", host_name);
            println!("{}", command.bright_white());

            match copy_to_clipboard(&command) {
                Ok(_) => println!("{}", "✓ Copied to clipboard".green()),
                Err(e) => println!("{} {}", "⚠ Could not copy to clipboard:".yellow(), e),
            }
            Ok(())
        }

        Commands::Update { execute } => handle_command("nix flake update", None, execute),

        Commands::Clean { execute } => handle_command("sudo nix-collect-garbage -d", None, execute),

        Commands::List => {
            println!("{}", "Available commands:".bold().cyan());
            println!(
                "  {} {}            - List all hosts",
                "dotDots".blue(),
                "hosts".green()
            );
            println!(
                "  {} {}      - Show host info",
                "dotDots".blue(),
                "info [host]".green()
            );
            println!(
                "  {} {}   - Rebuild host",
                "dotDots".blue(),
                "rebuild [host]".green()
            );
            println!(
                "  {} {}      - Test host",
                "dotDots".blue(),
                "test [host]".green()
            );
            println!(
                "  {} {}      - Boot host",
                "dotDots".blue(),
                "boot [host]".green()
            );
            println!(
                "  {} {}       - Dry build",
                "dotDots".blue(),
                "dry [host]".green()
            );
            println!(
                "  {} {}           - Update flake",
                "dotDots".blue(),
                "update".green()
            );
            println!(
                "  {} {}            - Clean garbage",
                "dotDots".blue(),
                "clean".green()
            );
            println!(
                "  {} {}             - List commands",
                "dotDots".blue(),
                "list".green()
            );
            println!(
                "  {} {}             - Show help",
                "dotDots".blue(),
                "help".green()
            );
            println!();
            println!(
                "{}",
                "Commands with [host] accept an optional host name.".dimmed()
            );
            println!("{}", "Default host:".dimmed(),);
            println!("  {}", get_current_host().green());
            println!();
            println!("{}", "Add --execute to run commands immediately".yellow());
            Ok(())
        }

        Commands::Help => {
            show_help();
            Ok(())
        }
    }
}
