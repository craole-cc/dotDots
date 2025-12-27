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
use chrono::Local;
use clap::{CommandFactory, Parser, Subcommand, ValueEnum};
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
  time::{Duration, SystemTime},
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

  /// Icon style for output
  #[arg(long, alias = "icon", alias = "icon_style", global = true, value_enum, default_value_t = IconStyle::Nerdfont)]
  icons: IconStyle,
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
    // /// Verbose output
    // #[arg(short, long)]
    // verbose: bool,
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

  /// Rollback to previous generation
  Rollback {
    #[arg(long)]
    execute: bool,
  },

  /// Interactive menu for common operations
  Interactive,

  /// System health check
  Healthcheck,

  /// Show enhanced help with examples
  Help,
}

#[derive(Clone, Copy, Debug)]
enum LogLevel {
  Success,
  Info,
  Debug,
  Warn,
  Error,
}

struct ConsoleStyle<'a> {
  level: LogLevel,
  icon: Option<&'a str>,
  leading: &'a str,
  trailing: &'a str,
  use_stderr: bool,
  colorize: fn(String) -> colored::ColoredString,
}

/// Icon display style
#[derive(ValueEnum, Clone, Copy, Debug, Default)]
enum IconStyle {
  /// Nerd Font icons (requires Nerd Font installed)
  #[default]
  Nerdfont,

  /// Unicode emoji icons
  Emoji,

  /// Plain text indicators
  Text,

  /// No icon display
  None,
}

impl IconStyle {
  fn success(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "✅  ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn debug(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "🔍  ",
      IconStyle::Text => "[DEBUG] ",
      IconStyle::None => "",
    })
  }

  fn info(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "ℹ️  ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn warning(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "⚠️  ",
      IconStyle::Text => "[WARNING] ",
      IconStyle::None => "",
    })
  }

  fn error(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "❌  ",
      IconStyle::Text => "[ERROR] ",
      IconStyle::None => "",
    })
  }

  fn target(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "󰓾  ",
      IconStyle::Emoji => "🎯  ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn build(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => " ",
      IconStyle::Emoji => "🔨 ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn sync(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "󱋖  ",
      IconStyle::Emoji => "🔄 ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn tree(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "🪾 ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn branch(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "🌐 ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }

  fn diff(&self, override_icon: Option<&'static str>) -> &'static str {
    override_icon.unwrap_or_else(|| match self {
      IconStyle::Nerdfont => "  ",
      IconStyle::Emoji => "📑 ",
      IconStyle::Text => "[INFO] ",
      IconStyle::None => "",
    })
  }
}

#[derive(Subcommand)]
enum CacheAction {
  /// Clear cache
  Clear {
    /// Force clear without confirmation
    #[arg(short, long)]
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
  icons: IconStyle,
}

impl DotDots {
  fn new(verbose: bool, quiet: bool, icons: IconStyle) -> Result<Self> {
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
      icons,
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

  /// Interactive menu for common operations
  fn interactive_mode(&self) -> Result<()> {
    let icon = self.icons.target(None);
    println!("{}", format!("{} Interactive Mode", icon).bold().cyan());
    println!("{}", "─".repeat(40).dimmed());
    println!();

    let options = vec![
      ("1", "Rebuild system", "rebuild"),
      ("2", "Update flake", "update"),
      ("3", "Show status", "status"),
      ("4", "Format files", "fmt"),
      ("5", "Run checks", "check"),
      ("6", "Sync changes", "sync"),
      ("q", "Quit", "quit"),
    ];

    for (key, desc, _) in &options {
      println!("  [{}] {}", key.cyan(), desc);
    }

    print!("\n{}", "Choose an option: ".yellow());
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    let choice = input.trim();

    match choice {
      "1" => self.handle_rebuild(None, true, false)?,
      "2" => self.handle_update(true, None)?,
      "3" => self.handle_status(false, false, false)?,
      "4" => self.handle_fmt(false)?,
      "5" => self.handle_check(false, false)?,
      "6" => self.handle_sync(&[], true, false, true)?,
      "q" => return Ok(()),
      _ => println!("{}", "Invalid option".red()),
    }

    Ok(())
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

    println!("{}", "🎯 NixOS Configuration REPL".bold().cyan()); // TODO: Use log_info
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
        self.log_error(&format!("Failed to list hosts: {}", e), None);
        println!("{}", "Are you in a Nix flake directory?".yellow());
      }
    }
    Ok(())
  }

  /// Show host information
  fn show_host_info(&self, host: Option<&str>, as_json: bool, detailed: bool) -> Result<()> {
    let host_name = host
      .map(String::from)
      .unwrap_or_else(Self::get_current_host);
    let cache_key = format!("host-info-{}", host_name);

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
          else if hostConfig.config.services.xserver.desktopManager.gnome.enable or false then "gnome"
          else if hostConfig.config.services.desktopManager.cosmic.enable or false then "cosmic"
          else "none"
        );
      }}
      "#,
      host_name.replace('\'', "'\\''")
    );

    // Use cached version with 5 minute TTL - DON'T call nix_eval again!
    match self.nix_eval_cached(&expr, &cache_key, Duration::from_secs(300)) {
      Ok(info) => {
        if as_json {
          println!("{}", serde_json::to_string_pretty(&info)?);
        } else {
          println!("{} {}", "Host:".bold().cyan(), host_name.green().bold());
          println!("{}", "─".repeat(40).dimmed());

          if let Some(obj) = info.as_object() {
            for (key, value) in obj {
              println!("  {:<15} {}", format!("{}:", key).cyan(), value);
            }
          }

          if detailed {
            println!();
            println!("{}", "Repository Statistics:".bold().cyan());
            let _ = Command::new("onefetch")
              .arg("--no-color-palette")
              .arg("--no-art")
              .status();

            println!();
            let _ = Command::new("tokei")
              .arg("--hidden")
              .arg("--num-format")
              .arg("commas")
              .status();
          }
        }
      }
      Err(_) => {
        self.log_error(&format!("Host not found: {}", host_name), None);
        println!("\n{}", "Available hosts:".yellow());
        self.list_hosts()?;
      }
    }

    Ok(())
  }

  /// Execute command with optional progress indicator
  fn execute_with_progress(
    &self,
    cmd: &str,
    name: &str,
    dir: Option<&Path>,
    show_progress: bool,
  ) -> Result<()> {
    if self.verbose && !self.quiet {
      self.log_debug(&format!("Executing: {}", cmd), None);
    }

    let mut process = Command::new("sh");
    process.arg("-c").arg(cmd);

    if let Some(dir) = dir {
      process.current_dir(dir);
    }

    // Add spinner for long-running commands
    let spinner = if show_progress && !self.quiet && self.config.options.progress {
      let sp = ProgressBar::new_spinner();
      sp.set_style(
        ProgressStyle::default_spinner()
          .template("{spinner:.cyan} {msg}")
          .unwrap(),
      );
      sp.set_message(format!("Running {}...", name));
      sp.enable_steady_tick(std::time::Duration::from_millis(100));
      Some(sp)
    } else {
      None
    };

    let status = process
      .stdin(Stdio::inherit())
      .stdout(Stdio::inherit())
      .stderr(Stdio::inherit())
      .status()
      .with_context(|| format!("Failed to execute {}", name))?;

    if let Some(sp) = spinner {
      sp.finish_and_clear();
    }

    if status.success() {
      Ok(())
    } else {
      anyhow::bail!(
        "Command failed with exit code: {}",
        status.code().unwrap_or(1)
      );
    }
  }

  /// Execute and return output (for display)
  fn execute_with_output(&self, cmd: &str, name: &str, dir: Option<&Path>) -> Result<String> {
    if self.verbose && !self.quiet {
      self.log_debug(&format!("Executing: {}", cmd), None);
    }

    let mut process = Command::new("sh");
    process.arg("-c").arg(cmd);
    if let Some(dir) = dir {
      process.current_dir(dir);
    }

    let output = process
      .stdin(Stdio::inherit())
      .stdout(Stdio::piped())
      .stderr(Stdio::inherit())
      .output()
      .with_context(|| format!("Failed to execute {}", name))?;

    if !output.status.success() {
      anyhow::bail!(
        "Command failed with exit code {}",
        output.status.code().unwrap_or(1)
      );
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
  }

  /// Run multiple commands in parallel (useful for checks, formatting, etc.)
  fn execute_parallel(
    &self,
    commands: Vec<(&str, &str)>, // (command, description)
  ) -> Result<Vec<Result<(), String>>> {
    use std::thread;

    let handles: Vec<_> = commands
      .into_iter()
      .map(|(cmd, desc)| {
        let cmd = cmd.to_string();
        let desc = desc.to_string();

        thread::spawn(move || {
          let output = Command::new("sh").arg("-c").arg(&cmd).output();

          match output {
            Ok(out) if out.status.success() => Ok(()),
            Ok(out) => Err(format!(
              "{}: {}",
              desc,
              String::from_utf8_lossy(&out.stderr)
            )),
            Err(e) => Err(format!("{}: {}", desc, e)),
          }
        })
      })
      .collect();

    let results = handles
      .into_iter()
      .map(|h| {
        h.join()
          .unwrap_or_else(|_| Err("Thread panicked".to_string()))
      })
      .collect();

    Ok(results)
  }

  /// Run a list of hooks
  fn run_hooks(&self, hooks: &[String]) -> Result<()> {
    for hook in hooks {
      if self.verbose {
        self.log_debug(&format!("Running hook: {}", hook), None);
      }
      self.execute(hook, "hook", None)?;
    }
    Ok(())
  }

  /// Resolve command aliases from config
  fn resolve_alias(&self, input: &str) -> String {
    self
      .config
      .aliases
      .get(input)
      .cloned()
      .unwrap_or_else(|| input.to_string())
  }

  /// Unified command execution flow
  fn handle_command_flow(
    &self,
    cmd: &str,
    execute: bool,
    action_desc: &str,
    pre_hooks: &[String],
    post_hooks: &[String],
  ) -> Result<()> {
    // Show command without executing
    if !execute {
      println!("{}", cmd.bright_white());
      if self.config.options.auto_copy {
        self.copy_to_clipboard(cmd)?;
      }
      self.log_info("Add --execute to run immediately", None);
      // println!("{}", "Add --execute to run immediately".yellow());
      return Ok(());
    }

    // 1. Execute pre-hooks
    self.run_hooks(pre_hooks)?;

    // 2. Log action
    self.log_info(action_desc, None);

    // 3. Resolve any aliases in command
    let resolved_cmd = self.resolve_alias(cmd);

    // 4. Execute with appropriate method based on command
    if action_desc.contains("nix-collect-garbage")
      || action_desc.contains("rollback")
      || action_desc.contains("rebuild")
    {
      // Destructive operations
      self.execute_safe(&resolved_cmd, action_desc, true)?;
    } else if self.config.options.progress
      && (action_desc.contains("fmt")
        || action_desc.contains("check")
        || action_desc.contains("rebuild"))
    {
      // Long-running with progress
      self.execute_with_progress(&resolved_cmd, action_desc, Some(&self.root), true)?;
    } else {
      // Standard execution
      self.execute(&resolved_cmd, action_desc, None)?;
    }

    // 5. Execute post-hooks
    self.run_hooks(post_hooks)?;

    // 6. Log success
    self.log_success(&format!("{} completed!", action_desc), None);
    Ok(())
  }

  fn handle_healthcheck(&self) -> Result<()> {
    self.log_info("Running system health checks...", None);

    let checks = vec![
      ("Flake valid", "nix flake check --no-build"),
      ("Git clean", "git status --porcelain"),
      ("Disk space", "df -h / | tail -1"),
      (
        "Nix store",
        "nix store optimise --dry-run 2>&1 | grep 'freed'",
      ),
    ];

    println!();
    for (name, cmd) in checks {
      print!("  {} ... ", name.cyan());
      io::stdout().flush()?;

      let output = Command::new("sh").arg("-c").arg(cmd).output()?;

      if output.status.success() {
        println!("{}", "✓".green());
      } else {
        println!("{}", "✗".red());
        if self.verbose {
          println!(
            "    {}",
            String::from_utf8_lossy(&output.stderr).trim().dimmed()
          );
        }
      }
    }

    Ok(())
  }

  /// Handle rebuild command
  fn handle_rebuild(&self, host: Option<&str>, execute: bool, command_only: bool) -> Result<()> {
    let host_name = host
      .map(String::from)
      .unwrap_or_else(Self::get_current_host);
    let cmd = format!("sudo nixos-rebuild switch --flake .#{}", host_name);

    if command_only {
      println!("{}", cmd);
      return Ok(());
    }

    self.handle_command_flow(
      &cmd,
      execute,
      "Rebuilding system",
      &self.config.hooks.pre_rebuild,
      &self.config.hooks.post_rebuild,
    )?;

    Ok(())
  }

  /// Handle test command
  fn handle_test(&self, host: Option<&str>, execute: bool) -> Result<()> {
    let host_name = host
      .map(String::from)
      .unwrap_or_else(Self::get_current_host);
    let cmd = format!("sudo nixos-rebuild test --flake .#{}", host_name);

    self.handle_command_flow(
      &cmd,
      execute,
      "Testing configuration",
      &[], // no pre hooks
      &[], // no post hooks
    )?;

    Ok(())
  }

  /// Handle boot command
  fn handle_boot(&self, host: Option<&str>, execute: bool) -> Result<()> {
    let host_name = host
      .map(String::from)
      .unwrap_or_else(Self::get_current_host);
    let cmd = format!("sudo nixos-rebuild boot --flake .#{}", host_name);

    self.handle_command_flow(&cmd, execute, "Building boot configuration", &[], &[])?;

    Ok(())
  }

  /// Handle dry command
  fn handle_dry(&self, host: Option<&str>, execute: bool) -> Result<()> {
    let host_name = match host {
      Some(h) => h.to_string(),
      None => Self::get_current_host(),
    };
    let cmd = format!("sudo nixos-rebuild dry-build --flake .#{}", host_name);

    self.handle_command_flow(&cmd, execute, "Building boot configuration", &[], &[])?;
    // println!("{}", cmd.bright_white());

    if self.config.options.auto_copy {
      self.copy_to_clipboard(&cmd)?;
    }

    // if verbose || self.verbose {
    //   self.log_info("Running dry build...", None);
    //   self.execute(&cmd, "nixos-rebuild", None)?;
    // }

    Ok(())
  }

  /// Handle update command
  fn handle_update(&self, execute: bool, input: Option<&str>) -> Result<()> {
    let resolved_input = self.resolve_alias(input.unwrap_or(""));
    let cmd = if !resolved_input.is_empty() {
      format!("nix flake update {}", resolved_input)
    } else {
      "nix flake update".to_string()
    };
    self.handle_command_flow(
      &cmd,
      execute,
      "Updating flake",
      &self.config.hooks.pre_update,
      &self.config.hooks.post_update,
    )?;

    Ok(())
  }

  /// Handle binit command
  fn handle_binit(&self, export: bool, profile: bool) -> Result<()> {
    let bin_dirs = self.find_bin_directories()?;

    if bin_dirs.is_empty() {
      self.log_warn("No bin directories found", None);
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
        self.log_success(&format!("Added to {}", profile_path.display()), None);
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
      self.log_info(
        &format!("Sync operation would commit with message: \"{}\"", msg),
        Some(self.icons.sync(None)),
      );
      self.log_info("To execute, add --execute flag", None);
      return Ok(());
    }

    if !yes && !self.config.options.auto_confirm {
      if !self.confirm("Proceed with sync?")? {
        self.log_info("Cancelled", None);
        return Ok(());
      }
    }

    self.log_info("Syncronization initialized\n", Some(self.icons.sync(None)));

    //> Stage all changes
    self.execute("git add --all", "git", Some(&self.root))?;

    //> Commit
    self.execute(
      &format!("git commit --message \"{}\"", msg),
      "git",
      Some(&self.root),
    )?;

    //> Push if enabled
    if push && self.config.git.auto_push {
      self.execute("git push", "git", Some(&self.root))?;
    }

    self.log_success("Syncronization complete!", Some(self.icons.sync(None)));
    Ok(())
  }

  /// Handle fmt command
  fn handle_fmt(&self, check: bool) -> Result<()> {
    self.log_info("Running formatters...", None);

    let treefmt_cmd = if check {
      "treefmt --fail-on-change"
    } else {
      "treefmt"
    };

    self.handle_command_flow(treefmt_cmd, true, "Formatting files", &[], &[])?;

    if check {
      self.log_success("All files are properly formatted!", None);
    } else {
      self.log_success("Formatting complete!", None);
    }

    Ok(())
  }

  /// Handle check command
  fn handle_check(&self, fix: bool, strict: bool) -> Result<()> {
    self.log_info("Running checks in parallel...", None);

    let checks = vec![
      ("treefmt --fail-on-change", "Format check"),
      ("nix flake check 2>&1 | head -20", "Flake check"),
    ];

    let results = self.execute_parallel(checks)?;

    let mut failed = Vec::new();
    for (i, result) in results.iter().enumerate() {
      match result {
        Ok(_) => self.log_success(&format!("✓ Check {} passed", i + 1), None),
        Err(e) => {
          self.log_error(&format!("✗ Check {} failed: {}", i + 1, e), None);
          failed.push(e);
        }
      }
    }

    if !failed.is_empty() {
      if fix {
        self.log_info("Attempting to fix issues...", None);
        self.execute("treefmt", "treefmt", None)?;
      } else if strict {
        anyhow::bail!("Strict mode: {} checks failed", failed.len());
      }
    } else {
      self.log_success("All checks passed!", None);
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

    self.handle_command_flow(&cmd, execute, "Cleaning garbage", &[], &[])?;
    Ok(())
  }

  /// Handle status command
  fn handle_status(&self, prompt: bool, hide_files: bool, hide_log: bool) -> Result<()> {
    if !self.is_git_repo(&self.root)? {
      if prompt {
        return Ok(());
      }
      self.log_error("Not a git repository", None);
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
      self.log_header(&branch, Some(self.icons.branch(None)));
      self.execute("git log --oneline -3", "git", Some(&self.root))?;
    }

    if changes > 0 {
      if hide_files {
        println!("{}", format!(" {}", changes.to_string()).magenta().bold());
      } else {
        self.log_header("", Some(self.icons.diff(None)));
        self.execute("git diff --stat", "git", Some(&self.root))?;

        self.log_header("", Some(self.icons.tree(None)));
        self.execute("git status --short", "git", Some(&self.root))?;
      }
    } else {
      println!("\n{}", " Repository is syncronized".magenta().bold());
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

    self.log_info("Starting Nix REPL...", None);
    self.execute(&cmd, "nix repl", None)?;

    Ok(())
  }

  /// Rollback to previous generation
  fn handle_rollback(&self, execute: bool) -> Result<()> {
    // Get current generation
    let current_gen = Command::new("sh")
        .arg("-c")
        .arg("sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -2 | head -1 | awk '{print $1}'")
        .output()?;

    let current = String::from_utf8_lossy(&current_gen.stdout)
      .trim()
      .parse::<i32>()
      .unwrap_or(0);

    if current <= 1 {
      self.log_warn("Already at oldest generation", None);
      return Ok(());
    }

    let previous = current - 1;

    // Show rollback info
    println!(
      "{}",
      format!("Rollback: generation {} → {}", current, previous).yellow()
    );

    let cmd = "sudo nixos-rebuild switch --rollback".to_string();

    self.handle_command_flow(
      &cmd,
      execute,
      "Rolling back to previous generation",
      &[],
      &[],
    )?;

    // Custom success message with sync icon
    self.log_success("Rolled back successfully!", Some(self.icons.build(None)));

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
    self.log_info(&format!("Searching for: {}", pattern), None);

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
      self.log_warn("No matches found", None);
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
            self.log_info("Cancelled", None);
            return Ok(());
          }
        }

        self.log_info("Clearing cache...", None);

        if self.cache_dir.exists() {
          fs::remove_dir_all(&self.cache_dir)?;
          fs::create_dir_all(&self.cache_dir)?;
          fs::create_dir_all(&self.logs_dir)?;
          fs::create_dir_all(&self.tmp_dir)?;
        }

        self.log_success("Cache cleared", None);
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

    self.log_success(
      &format!(
        "Generated {} completions at {}",
        shell,
        output_path.display()
      ),
      None,
    );

    println!("\nTo use these completions, add to your shell profile:");
    println!("  source {}", output_path.display());

    Ok(())
  }

  /// List all commands
  fn list_commands(&self, as_json: bool, names_only: bool) -> Result<()> {
    let commands = vec![
      ("interactive", "Interactive mode menu"),
      ("healthcheck", "Run system health checks"),
      ("rollback", "Rollback to previous generation"),
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

  /// Cached nix evaluation with TTL
  fn nix_eval_cached(
    &self,
    expr: &str,
    cache_key: &str,
    ttl: Duration,
  ) -> Result<serde_json::Value> {
    let cache_file = self.cache_dir.join(format!("{}.json", cache_key));

    // Check if cache is valid
    if cache_file.exists() {
      if let Ok(metadata) = fs::metadata(&cache_file) {
        if let Ok(modified) = metadata.modified() {
          if let Ok(elapsed) = SystemTime::now().duration_since(modified) {
            if elapsed < ttl {
              // Cache is still valid
              if let Ok(cached) = fs::read_to_string(&cache_file) {
                if let Ok(value) = serde_json::from_str(&cached) {
                  if self.verbose {
                    self.log_debug("Using cached result", None);
                  }
                  return Ok(value);
                }
              }
            }
          }
        }
      }
    }

    // Cache miss or expired - evaluate
    let result = self.nix_eval(expr)?;

    // Save to cache
    if let Ok(json_str) = serde_json::to_string_pretty(&result) {
      let _ = fs::write(&cache_file, json_str);
    }

    Ok(result)
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
  fn execute(&self, cmd: &str, name: &str, dir: Option<&Path>) -> Result<()> {
    if self.verbose && !self.quiet {
      self.log_debug(&format!("Executing: {}", cmd), None);
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

  /// Execute command with optional dry-run
  fn execute_safe(&self, cmd: &str, name: &str, is_destructive: bool) -> Result<()> {
    if is_destructive && !self.config.options.auto_confirm {
      println!("\n{}", "⚠️  This operation will:".yellow().bold());
      println!("   {}", cmd.white());

      if !self.confirm("Continue?")? {
        self.log_info("Cancelled", None);
        return Ok(());
      }
    }

    self.execute(cmd, name, None)
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

  /// Log to file and console
  fn log_to_file(&self, level: &str, msg: &str) -> Result<()> {
    use chrono::Local;

    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S");
    let log_file = self.logs_dir.join("dots.log");

    let log_entry = format!("[{}] {}: {}\n", timestamp, level, msg);

    // Append to log file
    if let Ok(mut file) = fs::OpenOptions::new()
      .create(true)
      .append(true)
      .open(&log_file)
    {
      let _ = file.write_all(log_entry.as_bytes());
    }

    Ok(())
  }

  fn log_to_console(&self, msg: &str, style: ConsoleStyle<'_>) {
    if self.quiet || (matches!(style.level, LogLevel::Debug) && !self.verbose) {
      return;
    }

    let icon = style.icon.unwrap_or_else(|| match style.level {
      LogLevel::Success => self.icons.success(None),
      LogLevel::Info => self.icons.info(None),
      LogLevel::Debug => self.icons.debug(None),
      LogLevel::Warn => self.icons.warning(None),
      LogLevel::Error => self.icons.error(None),
    });

    let text = format!("{}{}{}{}", style.leading, icon, msg, style.trailing);
    let colored = (style.colorize)(text);

    if style.use_stderr {
      eprintln!("{colored}");
    } else {
      println!("{colored}");
    }
  }

  fn log_header(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("INFO", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Info,
        icon: custom_icon,
        leading: "\n",
        trailing: "",
        use_stderr: false,
        colorize: |s| s.magenta().bold(),
      },
    );
  }

  fn log_success(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("SUCCESS", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Success,
        icon: custom_icon,
        leading: "\n",
        trailing: "",
        use_stderr: false,
        colorize: |s| s.green().bold(),
      },
    );
  }

  fn log_debug(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("DEBUG", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Debug,
        icon: custom_icon,
        leading: "",
        trailing: "",
        use_stderr: false,
        colorize: |s| s.magenta(),
      },
    );
  }

  fn log_info(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("INFO", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Info,
        icon: custom_icon,
        leading: "",
        trailing: "",
        use_stderr: false,
        colorize: |s| s.blue(),
      },
    );
  }

  fn log_warn(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("WARN", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Warn,
        icon: custom_icon,
        leading: "",
        trailing: "",
        use_stderr: true,
        colorize: |s| s.yellow(),
      },
    );
  }

  fn log_error(&self, msg: &str, custom_icon: Option<&'static str>) {
    let _ = self.log_to_file("ERROR", msg);
    self.log_to_console(
      msg,
      ConsoleStyle {
        level: LogLevel::Error,
        icon: custom_icon,
        leading: "",
        trailing: "",
        use_stderr: true,
        colorize: |s| s.red().bold(),
      },
    );
  }
}

fn main() -> Result<()> {
  let cli = Cli::parse();
  let dots = DotDots::new(cli.verbose, cli.quiet, cli.icons)?;

  match cli.command {
    None | Some(Commands::Help) => dots.show_help(),

    Some(Commands::Interactive) => dots.interactive_mode(),
    Some(Commands::Healthcheck) => dots.handle_healthcheck(),
    Some(Commands::Rollback { execute }) => dots.handle_rollback(execute),

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
    Some(Commands::Fmt { check }) => dots.handle_fmt(check),
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
