{
  lib,
  src,
  system,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues genAttrs mapAttrs;
  inherit (pkgs) writeShellApplication;

  #──────────────────────────────────────────────────────────────────────────────
  # Configuration
  #──────────────────────────────────────────────────────────────────────────────

  config = {
    name = "dotDots";
    version = "2.0.0";
    cacheDirDefault = ".cache";
    binDirName = "bin";
  };

  #──────────────────────────────────────────────────────────────────────────────
  # CLI Tools
  #──────────────────────────────────────────────────────────────────────────────

  #> Main dotDots script using rust-script
  rustScript = mkCmd {
    inherit (config) name;
    inputs = [pkgs.rust-script];
    command = ''exec rust-script ${src + "/Bin/rust/.dots.rs"} "$@"'';
  };

  #> Enhanced command builder with custom options
  mkCmd = {
    name,
    inputs ? [],
    env ? null,
    command,
    bashOptions ? ["errexit" "nounset" "pipefail"],
    excludeShellChecks ? [],
    meta ? {},
  }:
    writeShellApplication {
      inherit name bashOptions excludeShellChecks meta;
      runtimeInputs = inputs;
      runtimeEnv = env;
      text = command;
    };

  #> Command definitions with descriptions
  dotDotsCommands = {
    hosts = "List available hosts";
    info = "Display system information";
    rebuild = "Rebuild NixOS configuration";
    test = "Test configuration without switching";
    boot = "Build for next boot";
    dry = "Dry run of rebuild";
    update = "Update flake inputs";
    clean = "Clean up old generations";
    sync = "Sync configuration changes";
    binit = "Initialize bin directories";
    list = "List available commands";
    help = "Show help information";
  };

  #> Standalone commands with enhanced functionality
  standaloneCommands = {
    "repl" = {
      description = "Enter Nix REPL with flake loaded";
      command = ''exec nix repl --file ${src + "/default.nix"}'';
    };

    "fmt" = {
      description = "Format all files using treefmt";
      inputs = with pkgs; [treefmt];
      command = ''
        echo "🎨 Formatting all files with treefmt..."
        cd "$DOTS" || exit 1
        exec treefmt "$@"
      '';
    };

    "check" = {
      description = "Run all checks (format, lint, build)";
      inputs = with pkgs; [treefmt alejandra shellcheck];
      command = ''
        echo "🔍 Running checks..."
        cd "$DOTS" || exit 1

        echo "  → Checking formatting with treefmt..."
        treefmt --fail-on-change || { echo "❌ Format check failed. Run '.fmt' to fix."; exit 1; }

        echo "  → Checking shell scripts..."
        find "$DOTS" -type f \( -name "*.sh" -o -name "*.bash" \) -exec shellcheck {} + 2>/dev/null || { echo "❌ Shell check failed."; exit 1; }

        echo "✅ All checks passed!"
      '';
    };

    "status" = {
      description = "Show git status and system info";
      inputs = with pkgs; [git];
      command = ''
        echo "📊 Repository Status"
        echo "===================="
        echo "Host: $HOST_NAME ($HOST_TYPE)"
        echo "Location: $DOTS"
        echo ""
        git -C "$DOTS" status --short --branch
      '';
    };

    "backup" = {
      description = "Create backup of current configuration";
      inputs = with pkgs; [gnutar gzip];
      command = ''
        BACKUP_DIR="''${DOTS_BACKUP_DIR:-$HOME/.config/nixos-backups}"
        mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$BACKUP_DIR/dotdots_backup_$TIMESTAMP.tar.gz"

        echo "💾 Creating backup..."
        tar -czf "$BACKUP_FILE" -C "$(dirname "$DOTS")" "$(basename "$DOTS")" \
          --exclude='.cache' --exclude='result*' --exclude='.git'

        echo "✅ Backup created: $BACKUP_FILE"
      '';
    };
  };

  #> Generate command packages
  # commands =
  #   (genAttrs (attrNames dotDotsCommands) (
  #     cmd:
  #       mkCmd {
  #         name = ".${cmd}";
  #         inputs = [rustScript];
  #         command = ''exec dotDots ${cmd} "$@"'';
  #       }
  #   ))
  #   // (mapAttrs (
  #       name: cfg:
  #         mkCmd {
  #           inherit name;
  #           inherit (cfg) command packages;
  #         }
  #     )
  #     standaloneCommands);
  # commands =
  #   mapAttrs (
  #     name: cfg:
  #       mkCmd {
  #         inherit name;
  #         inherit (cfg) command packages;
  #       }
  #   )
  #   standaloneCommands;

  #──────────────────────────────────────────────────────────────────────────────
  # Package Groups (Organized & Optimized)
  #──────────────────────────────────────────────────────────────────────────────

  packageGroups = {
    core = with pkgs; [
      bat # Better cat
      fd # Better find
      gitui # Git TUI
      gnused # GNU sed
      lsd
      eza
      jq # JSON processor
      ripgrep # Better grep
      tokei # Code statistics
      yazi # File manager
    ];

    nix = with pkgs; [
      nil # Nix LSP
      nixd # Nix language server
      nix-tree # Visualize dependencies
      nix-output-monitor # Better build output
    ];

    git = with pkgs; [
      gh # GitHub CLI
      git-cliff # Changelog generator
      onefetch # Git repo summary
    ];

    rust = with pkgs; [
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
      rust-script
    ];

    clipboard = with pkgs; [
      xclip
      wl-clipboard
      xsel
    ];

    formatters = with pkgs; [
      # Nix formatters
      alejandra # Nix formatter (opinionated)
      nixfmt # Nix formatter (RFC style)

      # Shell formatters
      shellcheck # Shell script linter
      shfmt # Shell script formatter

      # Rust formatters
      rustfmt # Rust formatter (included in rust toolchain but explicit here)

      # Universal formatters
      treefmt # Multi-language formatter orchestrator

      # Markup & data formatters
      markdownlint-cli2 # Markdown linter
      taplo # TOML formatter
      yamlfmt # YAML formatter

      # Additional language formatters
      nodePackages.prettier # JS/TS/JSON/CSS/HTML/MD formatter
    ];

    utilities = with pkgs; [
      undollar # Remove $ from commands
      watchexec # File watcher
      direnv # Environment switcher
    ];
  };

  packages =
    []
    ++ (attrValues packageGroups.core)
    ++ (attrValues packageGroups.nix)
    ++ (attrValues packageGroups.git)
    ++ (attrValues packageGroups.rust)
    ++ (attrValues packageGroups.clipboard)
    ++ (attrValues packageGroups.formatters)
    ++ (attrValues packageGroups.utilities)
    # ++ (attrValues commands)
    # ++ [rustScript];
    ++ [];

  #──────────────────────────────────────────────────────────────────────────────
  # Shell Configuration
  #──────────────────────────────────────────────────────────────────────────────

  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    DOTS = toString src;
    DOTS_BIN = toString (src + "/Bin");
    DOTS_VERSION = config.version;
  };

  shellHook = ''
    #──────────────────────────────────────────────────────────────────────────────
    # Environment Setup
    #──────────────────────────────────────────────────────────────────────────────

    #> Override DOTS to point to actual repository, not Nix store
    export DOTS="$PWD"
    export DOTS_BIN="$DOTS/Bin"

    #> Dynamically determine host info
    export HOST_NAME="$(hostname)"
    export HOST_TYPE="${system}"

    #> Set up cache directory structure
    export DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${config.cacheDirDefault}"}"
    export ENV_BIN="$DOTS_CACHE/${config.binDirName}"
    export DOTS_LOGS="$DOTS_CACHE/logs"
    export DOTS_TMP="$DOTS_CACHE/tmp"

    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Color output support
    export CLICOLOR=1
    export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

    #──────────────────────────────────────────────────────────────────────────────
    # Initialization
    #──────────────────────────────────────────────────────────────────────────────

    #> Initialize bin directories
    if command -v dotDots >/dev/null 2>&1; then
      eval "$(dotDots binit 2>/dev/null || true)" 2>/dev/null || true
    fi

    #> Check for direnv
    if command -v direnv >/dev/null 2>&1 && [ -f "$DOTS/.envrc" ]; then
      eval "$(direnv hook bash 2>/dev/null)" 2>/dev/null || true
    fi

    #──────────────────────────────────────────────────────────────────────────────
    # Helper Functions
    #──────────────────────────────────────────────────────────────────────────────

    dots_git_status() {
      if [ -d "$DOTS/.git" ]; then
        local branch=$(git -C "$DOTS" branch --show-current 2>/dev/null)
        local changes=$(git -C "$DOTS" status --porcelain 2>/dev/null | wc -l)
        if [ "$changes" -gt 0 ]; then
          echo "[$branch +$changes]"
        else
          echo "[$branch]"
        fi
      fi
    }

    #> Enhanced PS1 with git info
    export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]\$(dots_git_status)\[\033[00m\]\$ "

    #──────────────────────────────────────────────────────────────────────────────
    # Welcome Message
    #──────────────────────────────────────────────────────────────────────────────

    if command -v dotDots >/dev/null 2>&1; then
      dotDots help
    else
      cat <<'EOF'
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                  🎯 NixOS dotDots Development Shell                    ║
    ╚════════════════════════════════════════════════════════════════════════╝
    EOF
      echo "    Version: ${config.version}"
      echo "    Host:    $HOST_NAME"
      echo "    System:  $HOST_TYPE"
      echo "    Path:    $DOTS"
      echo ""
      echo "  📦 Core Commands:"
      echo "    .rebuild  - Rebuild NixOS configuration"
      echo "    .test     - Test configuration without switching"
      echo "    .update   - Update flake inputs"
      echo "    .sync     - Commit and push changes"
      echo ""
      echo "  🛠️  Utilities:"
      echo "    .repl     - Enter Nix REPL"
      echo "    .fmt      - Format all files (Nix, Shell, Rust, TOML, YAML, etc.)"
      echo "    .check    - Run all checks"
      echo "    .status   - Show git status"
      echo "    .backup   - Create configuration backup"
      echo ""
      echo "  📚 Help:"
      echo "    .help     - Show all available commands"
      echo "    .list     - List commands with descriptions"
      echo ""

      # Check for treefmt.toml
      if [ ! -f "$DOTS/treefmt.toml" ]; then
        echo "  ⚠️  treefmt.toml not found. Create one for multi-language formatting:"
        echo "     https://treefmt.com/latest/configure/"
        echo ""
      fi
    fi

    #> CD to DOTS if not already there
    if [ "$PWD" != "$DOTS" ] && [ -d "$DOTS" ]; then
      cd "$DOTS" || true
    fi
  '';
in
  pkgs.mkShell {
    inherit (config) name;
    inherit packages env shellHook;

    #> Shell aliases for convenience
    shellAliases = {
      ll = "eza --long --almost-all --git";
      ".." = "cd ..";
      "..." = "cd ../..";
      grep = "rg";
      cat = "bat";
      find = "fd";
    };
  }
