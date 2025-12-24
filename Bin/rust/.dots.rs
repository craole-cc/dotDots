#!/usr/bin/env -S rust-script
//! ```cargo
//! [package]
//! name = "dotdots-cli"
//! version = "0.5.0"
//! edition = "2024"
//!
//! [dependencies]
//! clap = { version = "4.0", features = ["derive", "cargo"] }
//! anyhow = "1.0"
//! serde_json = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! toml = "0.8"
//! colored = "2.0"
//! arboard = "3.2"
//! dirs = "5.0"
//! walkdir = "2.5"
//! regex = "1.10"
//! indicatif = "0.17"
//! chrono = "0.4"
//! clap_complete = "4.0"
//! ```

use anyhow::{Context, Result};
use arboard::Clipboard;
use clap::{CommandFactory, Parser, Subcommand};
use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::{
  collections::HashMap,
  env, fs,
  io::{self, Write},
  path::{Path, PathBuf},
  process::{Command, Stdio},
};
use walkdir::WalkDir;

#[derive(Parser)]
#[command(
    name = "dotDots",
    about = "NixOS Configuration Management",
    long_about = None,
    disable_help_subcommand = true,
    version
)]
struct Cli {
  #[command(subcommand)]
  command: Option<Commands>,

  /// Verbose output
  #[arg(short, long, global = true)]
  verbose: bool,

  /// Quiet mode
  #[arg(short, long, global = true)]
  quiet: bool,
}

#[derive(Subcommand)]
enum Commands {
  /// List all configured hosts
  Hosts,

  /// Show detailed host information
  Info {
    /// Host name (default: current host)
    host: Option<String>,

    /// Show as JSON
    #[arg(long)]
    json: bool,

    /// Show additional information (slower)
    #[arg(long, alias = "detail", alias = "details")]
    #[arg(long)]
    detailed: bool,
  },

  /// Rebuild configuration (add --execute to run it)
  Rebuild {
    /// Host name (default: current host)
    host: Option<String>,

    /// Execute the command immediately
    #[arg(long)]
    execute: bool,

    /// Show only the command
    #[arg(long)]
    command: bool,
  },

  /// Test configuration (add --execute to run it)
  Test {
    /// Host name (default: current host)
    host: Option<String>,

    /// Execute the command immediately
    #[arg(long)]
    execute: bool,
  },

  /// Build boot configuration (add --execute to run it)
  Boot {
    /// Host name (default: current host)
    host: Option<String>,

    /// Execute the command immediately
    #[arg(long)]
    execute: bool,
  },

  /// Dry build configuration
  Dry {
    /// Host name (default: current host)
    host: Option<String>,

    /// Show verbose output
    #[arg(long)]
    verbose: bool,
  },

  /// Update flake inputs (add --execute to run it)
  Update {
    /// Execute the command immediately
    #[arg(long)]
    execute: bool,

    /// Update specific input
    #[arg(short, long)]
    input: Option<String>,
  },

  /// Clean garbage collection (add --execute to run it)
  Clean {
    /// Execute the command immediately
    #[arg(long)]
    execute: bool,

    /// Delete old generations
    #[arg(long)]
    delete_old: bool,

    /// Dry run
    #[arg(long)]
    dry_run: bool,
  },

  /// Initialize PATH with bin directories
  Binit {
    /// Export as shell commands
    #[arg(long)]
    export: bool,

    /// Add to shell profile
    #[arg(long)]
    profile: bool,
  },

  /// Commit and push all changes
  Sync {
    /// Commit message (default: "sync <timestamp>")
    message: Vec<String>,

    /// Execute the sync immediately
    #[arg(long)]
    execute: bool,

    /// Skip confirmation
    #[arg(short = 'y', long)]
    yes: bool,

    /// Push to remote
    #[arg(long, default_value = "true")]
    push: bool,
  },

  /// Format all files
  Fmt {
    /// Check only (don't format)
    #[arg(long)]
    check: bool,

    /// Verbose output
    #[arg(short, long)]
    verbose: bool,
  },

  /// Run checks (format, lint)
  Check {
    /// Fix automatically
    #[arg(long)]
    fix: bool,

    /// Exit on first error
    #[arg(long)]
    strict: bool,
  },

  /// Show repository status
  Status {
    /// Prompt mode (minimal output)
    #[arg(short, long)]
    prompt: bool,

    /// Hide files
    #[arg(long)]
    hide_files: bool,

    /// Hide log
    #[arg(long)]
    hide_log: bool,
  },

  /// Enter Nix REPL
  Repl {
    /// Expression to evaluate
    expr: Option<String>,

    /// Show types
    #[arg(long)]
    types: bool,
  },

  /// Search for patterns
  Search {
    /// Pattern to search
    pattern: String,

    /// Case insensitive
    #[arg(short = 'i', long)]
    insensitive: bool,

    /// File type filter
    #[arg(short = 't', long)]
    file_type: Option<String>,

    /// Limit results
    #[arg(short = 'n', long)]
    limit: Option<usize>,
  },

  /// Manage cache
  Cache {
    #[command(subcommand)]
    action: CacheAction,
  },

  /// Generate shell completions
  Completions {
    /// Shell type
    shell: clap_complete::Shell,

    /// Output directory
    #[arg(short, long)]
    output: Option<PathBuf>,
  },

  /// List all available commands
  List {
    /// Show as JSON
    #[arg(long)]
    json: bool,

    /// Show only command names
    #[arg(long)]
    names: bool,
  },

  /// Show enhanced help with examples
  Help,
}

#[derive(Subcommand)]
enum CacheAction {
  /// Clear cache
  Clear {
    /// Force clear without confirmation
    #[arg(short = 'f', long)]
    force: bool,
  },

  /// Show cache statistics
  Stats,

  /// List cached files
  List,
}

/// Configuration structures
#[derive(Debug, Deserialize, Serialize, Clone)]
struct DotsConfig {
  #[serde(default = "default_name")]
  name: String,

  #[serde(default)]
  git: GitConfig,

  #[serde(default)]
  options: Options,

  #[serde(default)]
  experimental_features: ExperimentalFeatures,

  #[serde(default)]
  excludes: Excludes,

  #[serde(default)]
  order_files: OrderFiles,

  #[serde(default)]
  includes: Vec<Include>,

  #[serde(default)]
  hooks: Hooks,

  #[serde(default)]
  aliases: HashMap<String, String>,
}

fn default_name() -> String {
  "dotDots".to_string()
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct GitConfig {
  #[serde(default = "default_git_user")]
  user: String,

  #[serde(default = "default_git_email")]
  email: String,

  #[serde(default)]
  submodules: HashMap<String, SubmoduleConfig>,

  #[serde(default)]
  auto_push: bool,

  #[serde(default)]
  signing_key: Option<String>,
}

fn default_git_user() -> String {
  "craole-cc".to_string()
}

fn default_git_email() -> String {
  "".to_string()
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct Options {
  #[serde(default = "default_tag")]
  tag: String,

  #[serde(default = "default_verbosity")]
  verbosity: String,

  #[serde(default, rename = "verbosePreference")]
  verbose_preference: String,

  #[serde(default, rename = "debugPreference")]
  debug_preference: String,

  #[serde(default, rename = "informationPreference")]
  information_preference: String,

  #[serde(default, rename = "warningPreference")]
  warning_preference: String,

  #[serde(default, rename = "errorActionPreference")]
  error_action_preference: String,

  #[serde(default)]
  auto_copy: bool,

  #[serde(default)]
  auto_confirm: bool,

  #[serde(default)]
  color: bool,

  #[serde(default)]
  progress: bool,
}

fn default_tag() -> String {
  "latest".to_string()
}

fn default_verbosity() -> String {
  "normal".to_string()
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct ExperimentalFeatures {
  #[serde(default)]
  enabled: Vec<String>,

  #[serde(default)]
  nix_command: bool,

  #[serde(default)]
  flakes: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct Excludes {
  #[serde(default)]
  patterns: Vec<String>,

  #[serde(default)]
  directories: Vec<String>,

  #[serde(default)]
  files: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct OrderFiles {
  #[serde(default)]
  filenames: Vec<String>,

  #[serde(default)]
  priority: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct Include {
  path: String,

  #[serde(default)]
  modules: Vec<String>,

  #[serde(default)]
  enabled: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct SubmoduleConfig {
  path: String,

  #[serde(default)]
  writable: bool,

  #[serde(default)]
  description: String,

  #[serde(default)]
  user: String,

  #[serde(default)]
  auto_sync: bool,

  #[serde(default)]
  branch: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
struct Hooks {
  #[serde(default)]
  pre_sync: Vec<String>,

  #[serde(default)]
  post_sync: Vec<String>,

  #[serde(default)]
  pre_rebuild: Vec<String>,

  #[serde(default)]
  post_rebuild: Vec<String>,

  #[serde(default)]
  pre_update: Vec<String>,

  #[serde(default)]
  post_update: Vec<String>,
}

/// Main application state
struct DotDots {
  config: DotsConfig,
  root: PathBuf,
  cache_dir: PathBuf,
  logs_dir: PathBuf,
  tmp_dir: PathBuf,
  verbose: bool,
  quiet: bool,
}

impl DotDots {
  fn new(verbose: bool, quiet: bool) -> Result<Self> {
    let dots_var = env::var("DOTS").context("DOTS environment variable not set")?;
    let root = PathBuf::from(&dots_var);
    let real_root = fs::canonicalize(&root).unwrap_or_else(|_| root.clone());

    let cache_base = real_root.join(".cache");
    let cache_dir = cache_base.join("dots");
    let logs_dir = cache_dir.join("logs");
    let tmp_dir = cache_dir.join("tmp");

    for dir in [&cache_dir, &logs_dir, &tmp_dir] {
      fs::create_dir_all(dir).context("Failed to create cache directory")?;
    }

    let config = Self::load_config(&real_root)?;

    Ok(Self {
      config,
      root: real_root,
      cache_dir,
      logs_dir,
      tmp_dir,
      verbose,
      quiet,
    })
  }

  fn load_config(root: &Path) -> Result<DotsConfig> {
    let config_filenames = [
      ".dots.toml",
      "dots.toml",
      "config.toml",
      ".config.toml",
      ".config/dots.toml",
      ".dots.json",
      "dots.json",
      ".dots.conf",
      ".dotsrc",
    ];

    let search_paths = vec![
      root.to_path_buf(),
      dirs::home_dir().unwrap_or_default(),
      dirs::home_dir().unwrap_or_default().join(".config"),
    ];

    for search_path in &search_paths {
      for filename in &config_filenames {
        let config_path = search_path.join(filename);
        if config_path.exists() {
          let config_str = fs::read_to_string(&config_path)
            .with_context(|| format!("Failed to read config at {}", config_path.display()))?;

          let config: DotsConfig = if filename.ends_with(".toml") {
            toml::from_str(&config_str).with_context(|| {
              format!("Failed to parse TOML config at {}", config_path.display())
            })?
          } else {
            serde_json::from_str(&config_str).with_context(|| {
              format!("Failed to parse JSON config at {}", config_path.display())
            })?
          };

          if search_path != root {
            eprintln!("Loaded config from: {}", config_path.display());
          }
          return Ok(config);
        }
      }
    }

    eprintln!("No config file found, using defaults");
    Ok(Self::default_config())
  }

  fn default_config() -> DotsConfig {
    let mut submodules = HashMap::new();
    submodules.insert(
      String::from("wallpapers"),
      SubmoduleConfig {
        path: String::from("Assets/Images/wallpaper"),
        writable: true,
        description: String::from("Wallpaper collection"),
        user: String::from("Craole"),
        auto_sync: true,
        branch: String::from("main"),
      },
    );

    DotsConfig {
      name: default_name(),
      git: GitConfig {
        user: default_git_user(),
        email: default_git_email(),
        submodules,
        auto_push: true,
        signing_key: None,
      },
      options: Options {
        tag: default_tag(),
        verbosity: default_verbosity(),
        verbose_preference: "Continue".to_string(),
        debug_preference: "Continue".to_string(),
        information_preference: "Continue".to_string(),
        warning_preference: "Continue".to_string(),
        error_action_preference: "Continue".to_string(),
        auto_copy: true,
        auto_confirm: false,
        color: true,
        progress: true,
      },
      experimental_features: ExperimentalFeatures {
        enabled: vec!["nix-command".to_string(), "flakes".to_string()],
        nix_command: true,
        flakes: true,
      },
      excludes: Excludes {
        patterns: vec![
          ".*".to_string(),
          "*.swp".to_string(),
          "*.tmp".to_string(),
          "*.log".to_string(),
        ],
        directories: vec![
          ".git".to_string(),
          "node_modules".to_string(),
          "target".to_string(),
          ".cache".to_string(),
          ".direnv".to_string(),
        ],
        files: vec![],
      },
      order_files: OrderFiles {
        filenames: vec![
          "default.nix".to_string(),
          "flake.nix".to_string(),
          "shell.nix".to_string(),
        ],
        priority: vec![
          "Configuration".to_string(),
          "hosts".to_string(),
          "modules".to_string(),
          "packages".to_string(),
        ],
      },
      includes: vec![],
      hooks: Hooks::default(),
      aliases: HashMap::new(),
    }
  }

  /// Get current host name from environment
  fn get_current_host() -> String {
    env::var("HOSTNAME").unwrap_or_else(|_| {
      if let Ok(output) = Command::new("hostname").output() {
        String::from_utf8_lossy(&output.stdout).trim().to_string()
      } else {
        "nixos".to_string()
      }
    })
  }

  /// Get current system from environment
  fn get_current_system() -> String {
    env::var("HOSTTYPE").unwrap_or_else(|_| "x86_64-linux".to_string())
  }

  /// Handle help command
  fn show_help(&self) -> Result<()> {
    let host = Self::get_current_host();
    let system = Self::get_current_system();

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
      "dots hosts".dimmed()
    );
    println!(
      "  {} or {}    - Show host information",
      ".info".cyan(),
      "dots info [host]".dimmed()
    );
    println!(
      "  {} or {} - Show rebuild command",
      ".rebuild".cyan(),
      "dots rebuild [host]".dimmed()
    );
    println!(
      "  {} or {}    - Show test command",
      ".test".cyan(),
      "dots test [host]".dimmed()
    );
    println!(
      "  {} or {}    - Show boot command",
      ".boot".cyan(),
      "dots boot [host]".dimmed()
    );
    println!(
      "  {} or {}     - Show dry-build command",
      ".dry".cyan(),
      "dots dry [host]".dimmed()
    );
    println!(
      "  {} or {}  - Show flake update command",
      ".update".cyan(),
      "dots update".dimmed()
    );
    println!(
      "  {} or {}   - Show garbage collection command",
      ".clean".cyan(),
      "dots clean".dimmed()
    );
    println!(
      "  {} or {}   - Initialize PATH with bin directories",
      ".binit".cyan(),
      "dots binit".dimmed()
    );
    println!(
      "  {} or {}    - Commit & push all changes",
      ".sync".cyan(),
      "dots sync [message]".dimmed()
    );
    println!(
      "  {} or {}    - Format all files",
      ".fmt".cyan(),
      "dots fmt".dimmed()
    );
    println!(
      "  {} or {}   - Run all checks",
      ".check".cyan(),
      "dots check".dimmed()
    );
    println!(
      "  {} or {}  - Show repository status",
      ".status".cyan(),
      "dots status".dimmed()
    );
    println!(
      "  {} or {}     - Enter Nix REPL",
      ".repl".cyan(),
      "dots repl".dimmed()
    );
    println!(
      "  {} or {}   - Search for patterns",
      ".search".cyan(),
      "dots search".dimmed()
    );
    println!(
      "  {} or {}   - Manage cache",
      ".cache".cyan(),
      "dots cache".dimmed()
    );
    println!(
      "  {} or {}    - List all commands",
      ".list".cyan(),
      "dots list".dimmed()
    );
    println!(
      "  {} or {}    - Show this help",
      ".help".cyan(),
      "dots help".dimmed()
    );
    println!();

    println!("{}", "Additional Tools:".bold().magenta());
    println!("  {}  - TUI for git operations", "gitui".cyan());
    println!("  {}  - Repository info and statistics", "onefetch".cyan());
    println!("  {}  - Code statistics", "tokei".cyan());
    println!("  {}  - Terminal file manager", "yazi".cyan());
    println!();

    println!("{}", "Options:".bold().magenta());
    println!("  Add --execute to any command to run it immediately");
    println!("  Commands automatically copy to clipboard when available");
    println!("  Use --verbose for detailed output");
    println!("  Use --quiet for minimal output");
    println!();

    println!("{}", "Quick usage:".bold().magenta());
    println!("  .rebuild              # Show rebuild command for current host");
    println!("  .rebuild --execute    # Run rebuild immediately");
    println!("  .rebuild QBX          # Show rebuild command for QBX");
    println!("  .update --execute     # Update flake");
    println!("  .sync \"my changes\"    # Commit & push submodule + dotDots");
    println!("  .sync --execute       # Commit & push everything immediately");
    println!("  .info                 # Show detailed host info with stats");
    println!("  .fmt                  # Format all files");
    println!("  .check                # Run checks");
    println!("  gitui                 # Open git TUI");
    println!();

    Ok(())
  }

  /// List all hosts
  fn list_hosts(&self) -> Result<()> {
    match self.nix_eval("builtins.attrNames (builtins.getFlake (toString ./.)).nixosConfigurations")
    {
      Ok(json) => {
        if let Some(hosts) = json.as_array() {
          println!("{}", "Available hosts:".bold().cyan());
          for host in hosts {
            if let Some(host_str) = host.as_str() {
              let current = Self::get_current_host();
              if host_str == current {
                println!("  • {} (current)", host_str.green().bold());
              } else {
                println!("  • {}", host_str.green());
              }
            }
          }
        } else {
          println!("{}", "No hosts found".yellow());
        }
      }
      Err(e) => {
        self.log_error(&format!("Failed to list hosts: {}", e));
        println!("{}", "Are you in a Nix flake directory?".yellow());
      }
    }
    Ok(())
  }

  /// Show host information
  fn show_host_info(&self, host: Option<&str>, as_json: bool, detailed: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };

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
      host_name.replace("'", "'\\''")
    );

    match self.nix_eval(&expr) {
      Ok(info) => {
        if as_json {
          println!("{}", serde_json::to_string_pretty(&info)?);
        } else {
          println!(
            "{} {}",
            "Host info for:".bold().cyan(),
            host_name.green().bold()
          );
          println!("{}", "=".repeat(40).dimmed());

          if let Some(obj) = info.as_object() {
            for (key, value) in obj {
              println!("{}: {}", key.bold().cyan(), value);
            }
          }

          println!();
          println!("{}", "Repository info:".bold().cyan());
          let _ = Command::new("onefetch")
            .arg("--no-color-palette")
            .arg("--no-art")
            .status();
          if detailed {
            let _ = Command::new("tokei")
              .arg("--hidden")
              .arg("--num-format")
              .arg("commas")
              .status();
          }
        }
      }
      Err(_) => {
        self.log_error(&format!("Error loading host: {}", host_name));
        println!("{}", "Available hosts:".yellow());
        self.list_hosts()?;
      }
    }

    Ok(())
  }

  /// Handle rebuild command
  fn handle_rebuild(&self, host: Option<&str>, execute: bool, command_only: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };
    let cmd = format!("sudo nixos-rebuild switch --flake .#{}", host_name);

    if command_only {
      println!("{}", cmd);
      return Ok(());
    }

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if execute {
      self.log_info("Executing rebuild...");
      self.execute_command(&cmd, "nixos-rebuild", None)?;
      self.log_success("Rebuild completed!");
    }

    Ok(())
  }

  /// Handle test command
  fn handle_test(&self, host: Option<&str>, execute: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };
    let cmd = format!("sudo nixos-rebuild test --flake .#{}", host_name);

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if execute {
      self.log_info("Testing configuration...");
      self.execute_command(&cmd, "nixos-rebuild", None)?;
      self.log_success("Test completed!");
    }

    Ok(())
  }

  /// Handle boot command
  fn handle_boot(&self, host: Option<&str>, execute: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };
    let cmd = format!("sudo nixos-rebuild boot --flake .#{}", host_name);

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if execute {
      self.log_info("Building boot configuration...");
      self.execute_command(&cmd, "nixos-rebuild", None)?;
      self.log_success("Boot configuration built!");
    }

    Ok(())
  }

  /// Handle dry command
  fn handle_dry(&self, host: Option<&str>, verbose: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };
    let cmd = format!("sudo nixos-rebuild dry-build --flake .#{}", host_name);

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if verbose || self.verbose {
      self.log_info("Running dry build...");
      self.execute_command(&cmd, "nixos-rebuild", None)?;
    }

    Ok(())
  }

  /// Handle update command
  fn handle_update(&self, execute: bool, input: Option<&str>) -> Result<()> {
    let cmd = if let Some(input_name) = input {
      format!("nix flake update {}", input_name)
    } else {
      "nix flake update".to_string()
    };

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if execute {
      self.log_info("Updating flake...");
      self.execute_command(&cmd, "nix", None)?;
      self.log_success("Flake updated!");
    }

    Ok(())
  }

  /// Handle clean command
  fn handle_clean(&self, execute: bool, delete_old: bool, dry_run: bool) -> Result<()> {
    let mut cmd = "sudo nix-collect-garbage".to_string();

    if delete_old {
      cmd.push_str(" --delete-old");
    }

    if dry_run {
      cmd.push_str(" --dry-run");
    }

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    if execute {
      self.log_info("Cleaning garbage...");
      self.execute_command(&cmd, "nix-collect-garbage", None)?;
      self.log_success("Garbage collection completed!");
    }

    Ok(())
  }

  /// Handle binit command
  fn handle_binit(&self, export: bool, profile: bool) -> Result<()> {
    let bin_dirs = self.find_bin_directories()?;

    if bin_dirs.is_empty() {
      self.log_warn("No bin directories found");
      return Ok(());
    }

    if export {
      for dir in &bin_dirs {
        if let Some(path_str) = dir.to_str() {
          println!("export PATH=\"{}:$PATH\"", path_str);
        }
      }
    } else if profile {
      let profile_path = dirs::home_dir().unwrap_or_default().join(".bashrc");

      let mut additions = String::new();
      for dir in &bin_dirs {
        if let Some(path_str) = dir.to_str() {
          additions.push_str(&format!("export PATH=\"{}:$PATH\"\n", path_str));
        }
      }

      if let Ok(mut file) = fs::OpenOptions::new()
        .append(true)
        .create(true)
        .open(&profile_path)
      {
        use std::io::Write;
        writeln!(file, "\n# Added by dots binit")?;
        write!(file, "{}", additions)?;
        self.log_success(&format!("Added to {}", profile_path.display()));
      }
    } else {
      println!("{}", "Found bin directories:".bold().cyan());
      for dir in &bin_dirs {
        println!("  • {}", dir.display());
      }

      println!("\n{}", "To add to PATH:".bold().yellow());
      println!("  eval $(dots binit --export)");
      println!("  dots binit --profile  # Add to .bashrc");
    }

    Ok(())
  }

  /// Handle sync command
  fn handle_sync(&self, message: &[String], execute: bool, yes: bool, push: bool) -> Result<()> {
    use chrono::Local;

    let msg = if message.is_empty() {
      format!("sync {}", Local::now().format("%Y-%m-%d %H:%M"))
    } else {
      message.join(" ")
    };

    let changes = self.get_git_changes(&self.root)?;
    if changes == 0 {
      println!("✨ Working tree clean");
      println!("Nothing to commit, skipping sync.");
      return Ok(());
    }

    //> Show detailed status so user can decide
    self.handle_status(false, false, false)?;
    println!();

    if !execute {
      self.log_info(&format!(
        "Sync operation would commit with message: \"{}\"",
        msg
      ));
      println!("\n{}", "To execute, add --execute flag".yellow());
      return Ok(());
    }

    if !yes && !self.config.options.auto_confirm {
      if !self.confirm("Proceed with sync?")? {
        self.log_info("Cancelled");
        return Ok(());
      }
    }

    self.log_info("Starting sync...");

    // Stage all changes
    self.execute_command("git add -A", "git", Some(&self.root))?;

    // Commit
    self.execute_command(
      &format!("git commit -m \"{}\"", msg),
      "git",
      Some(&self.root),
    )?;

    // Push if enabled
    if push && self.config.git.auto_push {
      self.execute_command("git push", "git", Some(&self.root))?;
    }

    self.log_success("Sync completed!");
    Ok(())
  }

  /// Handle fmt command
  fn handle_fmt(&self, check: bool, verbose: bool) -> Result<()> {
    self.log_info("Running formatters...");

    let treefmt_cmd = if check {
      "treefmt --fail-on-change"
    } else {
      "treefmt"
    };

    if verbose || self.verbose {
      self.log_debug(&format!("Command: {}", treefmt_cmd));
    }

    if !check {
      self.log_info("Formatting files...");
    }

    self.execute_command(treefmt_cmd, "treefmt", None)?;

    if check {
      self.log_success("All files are properly formatted!");
    } else {
      self.log_success("Formatting complete!");
    }

    Ok(())
  }

  /// Handle check command
  fn handle_check(&self, fix: bool, strict: bool) -> Result<()> {
    self.log_info("Running checks...");

    // Check formatting
    self.log_info("Checking formatting...");
    let fmt_result = self.execute_command("treefmt --fail-on-change", "treefmt", None);

    if fmt_result.is_err() {
      self.log_error("Format check failed");
      if fix {
        self.log_info("Attempting to fix formatting...");
        self.execute_command("treefmt", "treefmt", None)?;
        self.log_success("Formatting fixed");
      } else {
        self.log_info("Run 'dots fmt' to fix formatting");
        if strict {
          anyhow::bail!("Strict mode: exiting on first error");
        }
      }
    } else {
      self.log_success("Formatting OK");
    }

    // Check shell scripts
    self.log_info("Checking shell scripts...");
    let shell_scripts: Vec<PathBuf> = WalkDir::new(&self.root)
      .into_iter()
      .filter_map(|e| e.ok())
      .filter(|e| {
        let path = e.path();
        if !path.is_file() {
          return false;
        }

        // Check for shell scripts
        if let Some(ext) = path.extension() {
          if ext == "sh" || ext == "bash" {
            return true;
          }
        }

        // Check shebang
        if let Ok(content) = fs::read_to_string(path) {
          if content.starts_with("#!/bin/sh") || content.starts_with("#!/bin/bash") {
            return true;
          }
        }

        false
      })
      .map(|e| e.path().to_path_buf())
      .collect();

    if !shell_scripts.is_empty() {
      let pb = ProgressBar::new(shell_scripts.len() as u64);
      pb.set_style(
        ProgressStyle::default_bar()
          .template("{spinner:.green} [{bar:40.cyan/blue}] {pos}/{len} scripts")
          .unwrap(),
      );

      let mut failed = Vec::new();

      for script in shell_scripts {
        if self.verbose {
          self.log_debug(&format!("Checking: {}", script.display()));
        }

        let output = Command::new("shellcheck").arg(&script).output();

        match output {
          Ok(output) if !output.status.success() => {
            failed.push((script, String::from_utf8_lossy(&output.stderr).to_string()));
          }
          Err(_) => {
            // shellcheck not installed or failed
          }
          _ => {}
        }

        pb.inc(1);
      }

      pb.finish_and_clear();

      if !failed.is_empty() {
        self.log_warn(&format!("Found issues in {} shell scripts", failed.len()));
        if strict {
          for (script, error) in &failed {
            eprintln!("{}: {}", script.display(), error);
          }
          anyhow::bail!("Shell check failed");
        }
      } else {
        self.log_success("Shell scripts OK");
      }
    }

    self.log_success("All checks passed!");
    Ok(())
  }

  /// Handle status command
  fn handle_status(&self, prompt: bool, hide_files: bool, hide_log: bool) -> Result<()> {
    if !self.is_git_repo(&self.root)? {
      if prompt {
        return Ok(());
      }
      self.log_error("Not a git repository");
      return Ok(());
    }

    let branch = self.get_git_branch(&self.root)?;
    let changes = self.get_git_changes(&self.root)?;

    if prompt {
      if changes > 0 {
        print!("[{} +{}]", branch, changes);
      } else {
        print!("[{}]", branch);
      }
      io::stdout().flush()?;
      return Ok(());
    }

    if !hide_log {
      println!("{}", format!(" {}", branch).magenta().bold());
      self.execute_command("git log --oneline -3", "git", Some(&self.root))?;
    }

    if changes > 0 {
      if hide_files {
        println!("{}", format!(" {}", changes.to_string()).magenta().bold());
      } else {
        println!("\n{}", " ".magenta().bold());
        self.execute_command("git diff --stat", "git", Some(&self.root))?;
        println!("\n{}", "󰙅 ".magenta().bold());
        self.execute_command("git status --short", "git", Some(&self.root))?;
      }
    } else {
      println!("\n{}", " Repository already in sync".magenta().bold());
    }

    Ok(())
  }

  /// Handle repl command
  fn handle_repl(&self, expr: Option<&str>, show_types: bool) -> Result<()> {
    let mut cmd = "nix repl".to_string();

    if show_types {
      cmd.push_str(" --show-trace");
    }

    if let Some(expr) = expr {
      cmd.push_str(&format!(" --expr '{}'", expr));
    } else {
      cmd.push_str(" --file \"$DOTS/default.nix\"");
    }

    println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    self.log_info("Starting Nix REPL...");
    self.execute_command(&cmd, "nix repl", None)?;

    Ok(())
  }

  /// Handle search command
  fn handle_search(
    &self,
    pattern: &str,
    insensitive: bool,
    file_type: Option<&str>,
    limit: Option<usize>,
  ) -> Result<()> {
    self.log_info(&format!("Searching for: {}", pattern));

    let regex = if insensitive {
      Regex::new(&format!("(?i){}", regex::escape(pattern)))?
    } else {
      Regex::new(pattern)?
    };

    let mut results = Vec::new();
    let mut total_matches = 0;

    for entry in WalkDir::new(&self.root)
      .into_iter()
      .filter_map(|e| e.ok())
      .filter(|e| e.path().is_file())
    {
      let path = entry.path();

      // Apply file type filter
      if let Some(ft) = &file_type {
        if let Some(ext) = path.extension() {
          if ext.to_string_lossy() != *ft {
            continue;
          }
        } else {
          continue;
        }
      }

      // Skip excluded patterns
      if self.should_exclude(path) {
        continue;
      }

      if let Ok(content) = fs::read_to_string(path) {
        for (line_num, line) in content.lines().enumerate() {
          if regex.is_match(line) {
            let relative_path = path
              .strip_prefix(&self.root)
              .unwrap_or(path)
              .display()
              .to_string();

            results.push((relative_path, line_num + 1, line.to_string()));
            total_matches += 1;

            if let Some(limit) = limit {
              if total_matches >= limit {
                break;
              }
            }
          }
        }
      }

      if let Some(limit) = limit {
        if total_matches >= limit {
          break;
        }
      }
    }

    if results.is_empty() {
      self.log_warn("No matches found");
      return Ok(());
    }

    println!("Found {} matches:", total_matches);
    println!();

    for (path, line_num, line) in results {
      println!("{}:{}", path.cyan(), line_num.to_string().yellow());
      println!("  {}", line);
      println!();
    }

    Ok(())
  }

  /// Handle cache commands
  fn handle_cache(&self, action: &CacheAction) -> Result<()> {
    match action {
      CacheAction::Clear { force } => {
        if !force {
          if !self.confirm("Clear all cache files?")? {
            self.log_info("Cancelled");
            return Ok(());
          }
        }

        self.log_info("Clearing cache...");

        if self.cache_dir.exists() {
          fs::remove_dir_all(&self.cache_dir)?;
          fs::create_dir_all(&self.cache_dir)?;
          fs::create_dir_all(&self.logs_dir)?;
          fs::create_dir_all(&self.tmp_dir)?;
        }

        self.log_success("Cache cleared");
      }

      CacheAction::Stats => {
        let cache_size = Self::dir_size(&self.cache_dir)?;
        let log_size = Self::dir_size(&self.logs_dir)?;
        let tmp_size = Self::dir_size(&self.tmp_dir)?;

        println!("{}", "Cache Statistics".bold().cyan());
        println!("{}", "=".repeat(20).dimmed());
        println!();
        println!("Cache directory: {}", self.cache_dir.display());
        println!("Total size: {:.2} MB", cache_size as f64 / 1024.0 / 1024.0);
        println!("Logs: {:.2} MB", log_size as f64 / 1024.0 / 1024.0);
        println!("Temp files: {:.2} MB", tmp_size as f64 / 1024.0 / 1024.0);

        let log_files: Vec<_> = fs::read_dir(&self.logs_dir)?
          .filter_map(|e| e.ok())
          .collect();

        if !log_files.is_empty() {
          println!();
          println!("Log files ({}):", log_files.len());
          for entry in log_files {
            if let Ok(metadata) = entry.metadata() {
              println!(
                "  {} ({:.1} KB)",
                entry.file_name().to_string_lossy(),
                metadata.len() as f64 / 1024.0
              );
            }
          }
        }
      }

      CacheAction::List => {
        println!("{}", "Cached Files".bold().cyan());
        println!("{}", "=".repeat(20).dimmed());

        let list_files = |dir: &Path, prefix: &str| -> Result<()> {
          if dir.exists() {
            for entry in fs::read_dir(dir)? {
              let entry = entry?;
              let path = entry.path();
              if path.is_file() {
                println!("{}{}", prefix, entry.file_name().to_string_lossy());
              }
            }
          }
          Ok(())
        };

        println!("\nLogs:");
        list_files(&self.logs_dir, "  ")?;

        println!("\nTemp files:");
        list_files(&self.tmp_dir, "  ")?;
      }
    }

    Ok(())
  }

  /// Generate shell completions
  fn handle_completions(&self, shell: clap_complete::Shell, output: Option<&Path>) -> Result<()> {
    let mut app = Cli::command();
    let bin_name = "dots";

    let output_dir = match output {
      Some(path) => path.to_path_buf(),
      None => self.root.join("completions"),
    };
    fs::create_dir_all(&output_dir)?;

    let output_path = output_dir.join(format!("{}.{}", bin_name, shell));

    clap_complete::generate_to(shell, &mut app, bin_name, &output_dir)?;

    self.log_success(&format!(
      "Generated {} completions at {}",
      shell,
      output_path.display()
    ));

    println!("\nTo use these completions, add to your shell profile:");
    println!("  source {}", output_path.display());

    Ok(())
  }

  /// List all commands
  fn list_commands(&self, as_json: bool, names_only: bool) -> Result<()> {
    let commands = vec![
      ("hosts", "List all configured hosts"),
      ("info", "Show detailed host information"),
      ("rebuild", "Rebuild configuration"),
      ("test", "Test configuration"),
      ("boot", "Build boot configuration"),
      ("dry", "Dry build configuration"),
      ("update", "Update flake inputs"),
      ("clean", "Clean garbage collection"),
      ("binit", "Initialize PATH with bin directories"),
      ("sync", "Commit and push all changes"),
      ("fmt", "Format all files"),
      ("check", "Run checks (format, lint)"),
      ("status", "Show repository status"),
      ("repl", "Enter Nix REPL"),
      ("search", "Search for patterns"),
      ("cache", "Manage cache"),
      ("completions", "Generate shell completions"),
      ("list", "List all available commands"),
      ("help", "Show enhanced help with examples"),
    ];

    if as_json {
      let json_commands: Vec<HashMap<&str, &str>> = commands
        .iter()
        .map(|(name, desc)| {
          let mut map = HashMap::new();
          map.insert("name", *name);
          map.insert("description", *desc);
          map
        })
        .collect();
      println!("{}", serde_json::to_string_pretty(&json_commands)?);
    } else if names_only {
      for (name, _) in commands {
        println!("{}", name);
      }
    } else {
      println!("{}", "Available commands:".bold().cyan());
      println!("{}", "=".repeat(40).dimmed());
      println!();

      let max_name_len = commands
        .iter()
        .map(|(name, _)| name.len())
        .max()
        .unwrap_or(0);

      for (name, description) in commands {
        let padding = " ".repeat(max_name_len - name.len());
        println!("  {}{}  - {}", name.cyan(), padding, description);
      }

      println!();
      println!(
        "{}",
        "Use --help with any command for more details".yellow()
      );
    }

    Ok(())
  }

  /// Helper: Find bin directories
  fn find_bin_directories(&self) -> Result<Vec<PathBuf>> {
    let mut bin_dirs = Vec::new();

    // Add the main Bin directory if it exists
    let main_bin = self.root.join("Bin");
    if main_bin.is_dir() {
      bin_dirs.push(main_bin);
    }

    // Recursively find other bin directories
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

    visit_dirs(&self.root, &mut bin_dirs, 0)?;

    Ok(bin_dirs)
  }

  /// Helper: Execute nix eval command
  fn nix_eval(&self, expr: &str) -> Result<serde_json::Value> {
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

  /// Helper: Copy text to clipboard
  fn copy_to_clipboard(&self, text: &str) -> Result<()> {
    let mut clipboard = Clipboard::new().context("Failed to initialize clipboard")?;
    clipboard
      .set_text(text)
      .context("Failed to copy to clipboard")?;

    if !self.quiet {
      println!("{}", "✓ Copied to clipboard".green());
    }

    Ok(())
  }

  /// Helper: Execute a shell command
  fn execute_command(&self, cmd: &str, name: &str, dir: Option<&Path>) -> Result<()> {
    if self.verbose && !self.quiet {
      self.log_debug(&format!("Executing: {}", cmd));
    }

    let mut process = Command::new("sh");
    process.arg("-c").arg(cmd);

    if let Some(dir) = dir {
      process.current_dir(dir);
    }

    let status = process
      .stdin(Stdio::inherit())
      .stdout(Stdio::inherit())
      .stderr(Stdio::inherit())
      .status()
      .with_context(|| format!("Failed to execute {}", name))?;

    if status.success() {
      Ok(())
    } else {
      anyhow::bail!(
        "Command failed with exit code: {}",
        status.code().unwrap_or(1)
      );
    }
  }

  /// Helper: Check if path should be excluded
  fn should_exclude(&self, path: &Path) -> bool {
    let path_str = path.to_string_lossy();

    // Check excluded directories
    for dir in &self.config.excludes.directories {
      if path_str.contains(dir) {
        return true;
      }
    }

    // Check excluded patterns
    for pattern in &self.config.excludes.patterns {
      if let Ok(regex) = Regex::new(pattern) {
        if regex.is_match(&path_str) {
          return true;
        }
      }
    }

    false
  }

  /// Helper: Calculate directory size
  fn dir_size(path: &Path) -> Result<u64> {
    let mut total = 0;

    if path.is_dir() {
      for entry in fs::read_dir(path)? {
        let entry = entry?;
        let metadata = entry.metadata()?;

        if metadata.is_dir() {
          total += Self::dir_size(&entry.path())?;
        } else {
          total += metadata.len();
        }
      }
    }

    Ok(total)
  }

  /// Helper: Confirm action
  fn confirm(&self, prompt: &str) -> Result<bool> {
    if self.config.options.auto_confirm {
      return Ok(true);
    }

    print!("{} [y/N]: ", prompt);
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    Ok(input.trim().to_lowercase() == "y")
  }

  /// Helper: Get git branch
  fn get_git_branch(&self, path: &Path) -> Result<String> {
    let output = Command::new("git")
      .args([
        "-C",
        path.to_str().unwrap_or("."),
        "branch",
        "--show-current",
      ])
      .output()
      .context("Failed to get git branch")?;

    if output.status.success() {
      Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
      Ok("unknown".to_string())
    }
  }

  /// Helper: Get git changes count
  fn get_git_changes(&self, path: &Path) -> Result<usize> {
    let output = Command::new("git")
      .args(["-C", path.to_str().unwrap_or("."), "status", "--porcelain"])
      .output()
      .context("Failed to get git status")?;

    if output.status.success() {
      let count = String::from_utf8_lossy(&output.stdout).lines().count();
      Ok(count)
    } else {
      Ok(0)
    }
  }

  /// Helper: Check if directory is a git repository
  fn is_git_repo(&self, path: &Path) -> Result<bool> {
    Ok(
      Command::new("git")
        .args(["-C", path.to_str().unwrap_or("."), "rev-parse", "--git-dir"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false),
    )
  }

  /// Helper: Log info message
  fn log_info(&self, msg: &str) {
    if !self.quiet {
      println!("\n{}", format!(" {}", msg).blue());
    }
  }

  /// Helper: Log success message
  fn log_success(&self, msg: &str) {
    if !self.quiet {
      println!("\n{}", format!(" {}", msg).green());
    }
  }

  /// Helper: Log warning message
  fn log_warn(&self, msg: &str) {
    if !self.quiet {
      println!("\n{}", format!(" {}", msg).yellow());
    }
  }

  /// Helper: Log error message
  fn log_error(&self, msg: &str) {
    println!("\n{}", format!(" {}", msg).red());
  }

  /// Helper: Log debug message
  fn log_debug(&self, msg: &str) {
    if self.verbose && !self.quiet {
      println!("\n{}", format!(" {}", msg).dimmed());
    }
  }
}

fn main() -> Result<()> {
  let cli = Cli::parse();
  let dots = DotDots::new(cli.verbose, cli.quiet)?;

  match cli.command {
    None | Some(Commands::Help) => dots.show_help(),

    Some(Commands::Hosts) => dots.list_hosts(),

    Some(Commands::Info {
      host,
      json,
      detailed,
    }) => dots.show_host_info(host.as_deref(), json, detailed),

    Some(Commands::Rebuild {
      host,
      execute,
      command,
    }) => dots.handle_rebuild(host.as_deref(), execute, command),

    Some(Commands::Test { host, execute }) => dots.handle_test(host.as_deref(), execute),

    Some(Commands::Boot { host, execute }) => dots.handle_boot(host.as_deref(), execute),

    Some(Commands::Dry { host, verbose }) => dots.handle_dry(host.as_deref(), verbose),

    Some(Commands::Update { execute, input }) => dots.handle_update(execute, input.as_deref()),

    Some(Commands::Clean {
      execute,
      delete_old,
      dry_run,
    }) => dots.handle_clean(execute, delete_old, dry_run),

    Some(Commands::Binit { export, profile }) => dots.handle_binit(export, profile),

    Some(Commands::Sync {
      message,
      execute,
      yes,
      push,
    }) => dots.handle_sync(&message, execute, yes, push),

    Some(Commands::Fmt { check, verbose }) => dots.handle_fmt(check, verbose),

    Some(Commands::Check { fix, strict }) => dots.handle_check(fix, strict),

    Some(Commands::Status {
      prompt,
      hide_files,
      hide_log,
    }) => dots.handle_status(prompt, hide_files, hide_log),

    Some(Commands::Repl { expr, types }) => dots.handle_repl(expr.as_deref(), types),

    Some(Commands::Search {
      pattern,
      insensitive,
      file_type,
      limit,
    }) => dots.handle_search(&pattern, insensitive, file_type.as_deref(), limit),

    Some(Commands::Cache { action }) => dots.handle_cache(&action),

    Some(Commands::Completions { shell, output }) => {
      dots.handle_completions(shell, output.as_deref())
    }

    Some(Commands::List { json, names }) => dots.list_commands(json, names),
  }
}
