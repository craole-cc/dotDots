#!/usr/bin/env -S rust-script
//! Version: 0.1.2
//! ```cargo
//! [package]
//! name = "dotdots-cli"
//! version = "0.1.2"
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
use std::{
    env, fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};

#[derive(Parser)]
#[command(
    name = "dotDots",
    about = "NixOS Configuration Management",
    long_about = None,
    disable_help_subcommand = true
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
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

    /// Initialize PATH with bin directories
    Binit,

    /// Commit and push all changes (submodule + dotDots parent repo)
    Sync {
        /// Commit message (default: "sync <submodule>")
        message: Vec<String>,

        /// Execute the sync immediately
        #[arg(long)]
        execute: bool,
    },

    /// List all available commands
    List,

    /// Show enhanced help with examples
    Help,
}

/// Configuration for sync operation
struct SyncConfig {
    root: PathBuf,
    submodule_path: PathBuf,
    submodule_user: String,
    submodule_name: String,
    parent_user: String,
    parent_name: String,
}

impl SyncConfig {
    fn new() -> Result<Self> {
        // Get the actual repository root from DOTS environment variable
        let dots_var = env::var("DOTS").context("DOTS environment variable not set")?;
        let root = PathBuf::from(&dots_var);

        // Resolve the real path if it's a symlink or relative path
        let real_root = fs::canonicalize(&root).unwrap_or_else(|_| root.clone());

        Ok(Self {
            root: real_root.clone(),
            submodule_path: real_root.join("Configuration/hosts/Victus"),
            submodule_user: "Craole".to_string(),
            submodule_name: "Victus".to_string(),
            parent_user: "craole-cc".to_string(),
            parent_name: "dotDots".to_string(),
        })
    }
}

/// Get current host name from environment
fn get_current_host() -> String {
    env::var("HOST_NAME").unwrap_or_else(|_| "QBX".to_string())
}

/// Get current system from environment
fn get_current_system() -> String {
    env::var("HOST_PLATFORM").unwrap_or_else(|_| "x86_64-linux".to_string())
}

/// Find all bin directories in the repository
fn find_bin_directories() -> Result<Vec<PathBuf>> {
    let dots = env::var("DOTS").context("DOTS environment variable not set")?;
    let root = PathBuf::from(&dots);
    let real_root = fs::canonicalize(&root).unwrap_or(root);

    let mut bin_dirs = Vec::new();

    // Add the main Bin directory if it exists
    let main_bin = real_root.join("Bin");
    if main_bin.is_dir() {
        bin_dirs.push(main_bin);
    }

    // Recursively find other bin directories (limit depth to avoid performance issues)
    fn visit_dirs(dir: &Path, bin_dirs: &mut Vec<PathBuf>, depth: usize) -> Result<()> {
        if depth > 3 {
            return Ok(());
        }

        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();

                // Skip hidden directories and common exclusions
                if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                    if name.starts_with('.') || name == "node_modules" || name == "target" {
                        continue;
                    }
                }

                if path.is_dir() {
                    if path.file_name().and_then(|n| n.to_str()) == Some("bin") {
                        bin_dirs.push(path.clone());
                    }
                    let _ = visit_dirs(&path, bin_dirs, depth + 1);
                }
            }
        }
        Ok(())
    }

    visit_dirs(&real_root, &mut bin_dirs, 0)?;

    Ok(bin_dirs)
}

/// Initialize PATH with bin directories
fn handle_binit() -> Result<()> {
    let bin_dirs = find_bin_directories()?;

    if bin_dirs.is_empty() {
        return Ok(());
    }

    // Generate export commands for shell evaluation
    for dir in bin_dirs {
        if let Some(path_str) = dir.to_str() {
            println!("export PATH=\"{}:$PATH\"", path_str);
        }
    }

    Ok(())
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

/// Check if GitHub CLI is available
fn check_gh_available() -> Result<()> {
    Command::new("gh")
        .arg("--version")
        .output()
        .context("GitHub CLI (gh) is not installed")?;
    Ok(())
}

/// Switch GitHub user
fn switch_gh_user(user: &str) -> Result<()> {
    println!("➡️  Switching to GitHub user: {}...", user.cyan());

    let status = Command::new("gh")
        .args(["auth", "switch", "--user", user])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .context("Failed to execute gh auth switch")?;

    if !status.success() {
        anyhow::bail!("Failed to switch GitHub user to {}", user);
    }

    Ok(())
}

/// Check if directory is a git repository
fn is_git_repo(path: &Path) -> bool {
    Command::new("git")
        .args(["-C", path.to_str().unwrap(), "rev-parse", "--git-dir"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

/// Check if there are uncommitted changes (modified, untracked, or staged files)
fn has_changes(path: &Path) -> Result<bool> {
    // Check for modified or deleted files
    let status_output = Command::new("git")
        .args(["-C", path.to_str().unwrap(), "status", "--porcelain"])
        .output()
        .context("Failed to check git status")?;

    Ok(!status_output.stdout.is_empty())
}

/// Execute git command in a directory
fn git_command(path: &Path, args: &[&str]) -> Result<()> {
    let mut cmd = Command::new("git");
    cmd.arg("-C").arg(path.to_str().unwrap());

    for arg in args {
        cmd.arg(arg);
    }

    let status = cmd
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .context(format!("Failed to execute git {:?}", args))?;

    if !status.success() {
        anyhow::bail!("Git command failed: {:?}", args);
    }

    Ok(())
}

/// Sync submodule repository (mimics git syncVictus)
fn sync_submodule(config: &SyncConfig, message: &str) -> Result<()> {
    println!(
        "➡️  Processing {} submodule...",
        config.submodule_name.cyan()
    );

    if !config.submodule_path.exists() {
        println!(
            "⚠️  Submodule directory does not exist: {:?}",
            config.submodule_path
        );
        return Ok(());
    }

    if !is_git_repo(&config.submodule_path) {
        println!(
            "⚠️  {} directory is not a git repository",
            config.submodule_name
        );
        return Ok(());
    }

    switch_gh_user(&config.submodule_user)?;

    if has_changes(&config.submodule_path)? {
        println!("➡️  Changes detected in {}", config.submodule_name.cyan());

        git_command(&config.submodule_path, &["add", "-A"])?;
        git_command(&config.submodule_path, &["commit", "-m", message])?;
        git_command(&config.submodule_path, &["push"])?;

        println!("✅ {} submodule synced", config.submodule_name.green());
    } else {
        println!("📌 No changes in {} submodule", config.submodule_name);
    }

    Ok(())
}

/// Sync parent repository (mimics git syncDots)
fn sync_parent_repo(config: &SyncConfig, message: &str) -> Result<()> {
    println!(
        "➡️  Processing {} parent repository...",
        config.parent_name.cyan()
    );

    if !is_git_repo(&config.root) {
        anyhow::bail!("{} directory is not a git repository", config.parent_name);
    }

    switch_gh_user(&config.parent_user)?;

    // Check if there are any changes
    if !has_changes(&config.root)? {
        println!("📌 No changes in {} parent repository", config.parent_name);
        return Ok(());
    }

    println!("➡️  Changes detected in {}", config.parent_name.cyan());

    // Stage all changes
    git_command(&config.root, &["add", "-A"])?;

    // Commit with the provided message
    git_command(&config.root, &["commit", "-m", message])?;

    // Push changes
    git_command(&config.root, &["push"])?;

    println!(
        "✅ {} parent repository updated",
        config.parent_name.green()
    );

    Ok(())
}

/// Handle sync command - execute the sync operation
fn handle_sync(message: Vec<String>, execute: bool) -> Result<()> {
    let config = SyncConfig::new()?;

    let msg = if message.is_empty() {
        format!("sync {}", config.submodule_name)
    } else {
        message.join(" ")
    };

    if !execute {
        println!("{}", "Sync operation will:".bold().cyan());
        println!(
            "  1. Commit & push {} submodule (if changes exist)",
            config.submodule_name.green()
        );
        println!(
            "  2. Update submodule pointer in {}",
            config.parent_name.green()
        );
        println!("  3. Commit & push {}", config.parent_name.green());
        println!("\n{}", format!("Message: \"{}\"", msg).yellow());
        println!(
            "\n{}",
            "💡 Tip: Add --execute to run the sync immediately".yellow()
        );
        return Ok(());
    }

    // Execute the sync
    println!("➡️  Starting complete sync: {}", msg.cyan());
    println!(
        "➡️  This will commit & push both {} and {}",
        config.submodule_name.cyan(),
        config.parent_name.cyan()
    );
    println!();

    check_gh_available()?;

    // Sync submodule first
    sync_submodule(&config, &msg)?;

    // Then sync parent repo (which includes submodule pointer if it changed)
    let parent_msg = if config.submodule_path.exists() && is_git_repo(&config.submodule_path) {
        // Check if submodule pointer changed
        let submodule_rel = config
            .submodule_path
            .strip_prefix(&config.root)
            .ok()
            .and_then(|p| p.to_str());

        if let Some(submodule_path) = submodule_rel {
            let status_output = Command::new("git")
                .args([
                    "-C",
                    config.root.to_str().unwrap(),
                    "status",
                    "--porcelain",
                    submodule_path,
                ])
                .output();

            if let Ok(output) = status_output {
                if !output.stdout.is_empty() {
                    format!("bump {} submodule: {}", config.submodule_name, msg)
                } else {
                    msg.clone()
                }
            } else {
                msg.clone()
            }
        } else {
            msg.clone()
        }
    } else {
        msg.clone()
    };

    sync_parent_repo(&config, &parent_msg)?;

    println!(
        "\n✅ {}",
        format!(
            "Complete: All changes committed and pushed to {} + {}",
            config.submodule_name, config.parent_name
        )
        .green()
        .bold()
    );

    Ok(())
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

/// Show host information with enhanced stats
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

            // Show git info if available
            println!("\n{}", "Repository info:".bold().cyan());
            let _ = Command::new("onefetch")
                .arg("--no-color-palette")
                .arg("--no-art")
                .status();

            // Show code statistics if available
            println!("\n{}", "Code statistics:".bold().cyan());
            let _ = Command::new("tokei").status();

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

    println!(
        "{}",
        "Available commands (prefix with . or use dotDots):"
            .bold()
            .magenta()
    );
    println!();

    println!("{}", "Command Wrappers (prefixed with .):".bold().white());
    println!(
        "  {} or {}  - List all configured hosts",
        ".hosts".cyan(),
        "dotDots hosts".dimmed()
    );
    println!(
        "  {} or {}    - Show host information",
        ".info".cyan(),
        "dotDots info [host]".dimmed()
    );
    println!(
        "  {} or {} - Show rebuild command",
        ".rebuild".cyan(),
        "dotDots rebuild [host]".dimmed()
    );
    println!(
        "  {} or {}    - Show test command",
        ".test".cyan(),
        "dotDots test [host]".dimmed()
    );
    println!(
        "  {} or {}    - Show boot command",
        ".boot".cyan(),
        "dotDots boot [host]".dimmed()
    );
    println!(
        "  {} or {}     - Show dry-build command",
        ".dry".cyan(),
        "dotDots dry [host]".dimmed()
    );
    println!(
        "  {} or {}  - Show flake update command",
        ".update".cyan(),
        "dotDots update".dimmed()
    );
    println!(
        "  {} or {}   - Show garbage collection command",
        ".clean".cyan(),
        "dotDots clean".dimmed()
    );
    println!(
        "  {} or {}   - Initialize PATH with bin directories",
        ".binit".cyan(),
        "dotDots binit".dimmed()
    );
    println!(
        "  {} or {}    - Commit & push all changes (submodule + dotDots)",
        ".sync".cyan(),
        "dotDots sync [message]".dimmed()
    );
    println!(
        "  {} or {}    - List all commands",
        ".list".cyan(),
        "dotDots list".dimmed()
    );
    println!(
        "  {} or {}    - Show this help",
        ".help".cyan(),
        "dotDots help".dimmed()
    );
    println!();

    println!("{}", "Additional Tools:".bold().magenta());
    println!("  {}  - TUI for git operations", "gitui".cyan());
    println!("  {}  - Repository info and statistics", "onefetch".cyan());
    println!("  {}  - Code statistics", "tokei".cyan());
    println!();

    println!("{}", "Options:".bold().magenta());
    println!("  Add --execute to any command to run it immediately");
    println!("  Commands automatically copy to clipboard when available");
    println!();

    println!("{}", "Quick usage:".bold().magenta());
    println!("  .rebuild              # Show rebuild command for current host");
    println!("  .rebuild --execute    # Run rebuild immediately");
    println!("  .rebuild QBX          # Show rebuild command for QBX");
    println!("  .update --execute     # Update flake");
    println!("  .sync \"my changes\"    # Commit & push submodule + dotDots");
    println!("  .sync --execute       # Commit & push everything immediately");
    println!("  .info                 # Show detailed host info with stats");
    println!("  gitui                 # Open git TUI");
    println!();
}

fn main() -> Result<()> {
    let args = Cli::parse();

    match args.command {
        None | Some(Commands::Help) => {
            show_help();
            Ok(())
        }

        Some(Commands::Hosts) => list_hosts(),

        Some(Commands::Info { host }) => show_host_info(host),

        Some(Commands::Rebuild { host, execute }) => {
            handle_command("sudo nixos-rebuild switch --flake .#{}", host, execute)
        }

        Some(Commands::Test { host, execute }) => {
            handle_command("sudo nixos-rebuild test --flake .#{}", host, execute)
        }

        Some(Commands::Boot { host, execute }) => {
            handle_command("sudo nixos-rebuild boot --flake .#{}", host, execute)
        }

        Some(Commands::Dry { host }) => {
            let host_name = host.unwrap_or_else(get_current_host);
            let command = format!("sudo nixos-rebuild dry-build --flake .#{}", host_name);
            println!("{}", command.bright_white());

            match copy_to_clipboard(&command) {
                Ok(_) => println!("{}", "✓ Copied to clipboard".green()),
                Err(e) => println!("{} {}", "⚠ Could not copy to clipboard:".yellow(), e),
            }
            Ok(())
        }

        Some(Commands::Update { execute }) => handle_command("nix flake update", None, execute),

        Some(Commands::Clean { execute }) => {
            handle_command("sudo nix-collect-garbage -d", None, execute)
        }

        Some(Commands::Binit) => handle_binit(),

        Some(Commands::Sync { message, execute }) => handle_sync(message, execute),

        Some(Commands::List) => {
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
                "  {} {}            - Init bin paths",
                "dotDots".blue(),
                "binit".green()
            );
            println!(
                "  {} {} - Commit & push everything",
                "dotDots".blue(),
                "sync [message]".green()
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
                "💡 Tip: Use dot prefix for quick access: .hosts, .info, .rebuild, .sync, etc."
                    .bright_yellow()
            );
            println!();
            println!(
                "{}",
                "Commands with [host] accept an optional host name.".dimmed()
            );
            println!("{}", "Default host:".dimmed());
            println!("  {}", get_current_host().green());
            println!();
            println!("{}", "Add --execute to run commands immediately".yellow());
            Ok(())
        }
    }
}
