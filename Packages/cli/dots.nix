{
  lib,
  src,
  system,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs attrValues filterAttrs genAttrs;
  inherit (pkgs) writeShellApplication;

  #──────────────────────────────────────────────────────────────────────────────
  # Configuration
  #──────────────────────────────────────────────────────────────────────────────

  config = {
    name = "dotDots";
    version = "2.0.0";
    cacheDirDefault = ".cache";
    binDirName = "bin";
    prefix = "_";
  };

  #──────────────────────────────────────────────────────────────────────────────
  # CLI Tools
  #──────────────────────────────────────────────────────────────────────────────

  #> Enhanced command builder
  mkApp = {
    name,
    inputs ? [],
    command,
  }:
    writeShellApplication {
      inherit name;
      runtimeInputs = inputs;
      text = command;
    };

  #> Main dotDots script using rust-script
  main = mkApp {
    inherit (config) name;
    inputs = [pkgs.rust-script];
    command = ''exec rust-script ${src + "/Bin/rust/.dots.rs"} "$@"'';
  };

  commands = {
    main = [
      "hosts"
      "info"
      "rebuild"
      "test"
      "boot"
      "dry"
      "update"
      "clean"
      "sync"
      "binit"
      "list"
      "help"
    ];

    repl = {
      inputs = [];
      command = ''exec nix repl --file ${src + "/default.nix"}'';
    };
    fmt = {
      inputs = with pkgs; [treefmt];
      command = ''
        printf "🎨 Formatting all files with treefmt...\n"
        cd "$DOTS" || exit 1
        exec treefmt "$@"
      '';
    };
    check = {
      inputs = with pkgs; [treefmt shellcheck];
      command = ''
        printf "🔍 Running checks...\n"
        cd "$DOTS" || exit 1
        printf "  → Checking formatting...\n"
        if ! treefmt --fail-on-change; then
          printf "❌ Format check failed. Run '.fmt' to fix.\n"
          exit 1
        fi
        printf "  → Checking shell scripts...\n"
        if ! find "$DOTS" -type f \( -name "*.sh" -o -name "*.bash" \) -exec shellcheck {} + 2>/dev/null; then
          printf "❌ Shell check failed.\n"
          exit 1
        fi
        printf "✅ All checks passed!\n"
      '';
    };
    status = {
      inputs = with pkgs; [git];
      command = ''
        printf "📊 Repository Status\n"
        printf "====================\n"
        printf "Host: %s (%s)\n" "$HOST_NAME" "$HOST_TYPE"
        printf "Location: %s\n" "$DOTS"
        printf "\n"
        git -C "$DOTS" status --short --branch
      '';
    };
  };

  apps =
    #> Generate dotDots wrappers (with . prefix)
    (genAttrs commands.main (
      cmd:
        mkApp {
          name = "${config.prefix}${cmd}";
          inputs = [main];
          command = ''exec dotDots ${cmd} "$@"'';
        }
    ))
    #> Add standalone commands (with . prefix)
    // (mapAttrs (
        name: cfg:
          mkApp {
            name = "${config.prefix}${name}";
            inherit (cfg) inputs command;
          }
      )
      (filterAttrs (name: _: name != "main") commands));

  #──────────────────────────────────────────────────────────────────────────────
  # Packages
  #──────────────────────────────────────────────────────────────────────────────

  packages =
    [main]
    ++ (attrValues apps)
    ++ (with pkgs; ([
      ]
      ++ [
        #~@ Rust
        rustc
        cargo
        rust-analyzer
        rustfmt
        rust-script
        clippy
      ]
      ++ [
        #~@ Formatters
        alejandra
        markdownlint-cli2
        nixfmt
        shellcheck
        shfmt
        taplo
        treefmt
        yamlfmt
      ]
      ++ [
        #~@ Clipboard
        xclip
        wl-clipboard
        xsel
      ]
      ++ [
        #~@ Utilities
        bat
        direnv
        eza
        fd
        gitui
        gnused
        jq
        mpv
        nil
        nix-output-monitor
        nix-tree
        nixd
        onefetch
        ripgrep
        tokei
        undollar
        watchexec
        yazi
        yazi
      ]));

  #──────────────────────────────────────────────────────────────────────────────
  # Shell Configuration
  #──────────────────────────────────────────────────────────────────────────────

  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    # DOTS = toString src;
    # DOTS_BIN = toString (src + "/Bin");
    DOTS_VERSION = config.version;
  };

  #> Override DOTS to point to actual repository, not Nix store
  # export DOTS="$PWD"
  # export DOTS_BIN="$DOTS/Bin"
  shellHook = with config; ''

    #> Dynamically determine host info
    export HOST_NAME="$(hostname)"
    export HOST_TYPE="${system}"

    #> Set up cache directory structure
    export DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${cacheDirDefault}"}"
    export ENV_BIN="$DOTS_CACHE/${binDirName}"
    export DOTS_LOGS="$DOTS_CACHE/logs"
    export DOTS_TMP="$DOTS_CACHE/tmp"
    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Color output support
    export CLICOLOR=1

    #> Initialize bin directories
    if command -v dotDots >/dev/null 2>&1; then
      eval "$(dotDots binit 2>/dev/null || true)" 2>/dev/null || true
    fi

    #> Check for direnv
    if command -v direnv >/dev/null 2>&1 && [ -f "$DOTS/.envrc" ]; then
      eval "$(direnv hook bash 2>/dev/null)" 2>/dev/null || true
    fi

    #> Git status helper
    dots_git_status() {
      if [ -d "$DOTS/.git" ]; then
        local branch
        branch=$(git -C "$DOTS" branch --show-current 2>/dev/null)
        local changes
        changes=$(git -C "$DOTS" status --porcelain 2>/dev/null | wc -l)
        if [ "$changes" -gt 0 ]; then
          printf "[%s +%s]" "$branch" "$changes"
        else
          printf "[%s]" "$branch"
        fi
      fi
    }

    #> Enhanced PS1 with git info
    export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]\$(dots_git_status)\[\033[00m\]\$ "

    #> Display welcome message
    if command -v dotDots >/dev/null 2>&1; then
      dotDots help
    else
      cat <<EOF
    🎯 NixOS Configuration Shell
    ============================

    Version: ${version}
    Current host: $HOST_NAME
    System: $HOST_TYPE

    📦 Core Commands:
      ${prefix}rebuild  - Rebuild NixOS configuration
      ${prefix}test     - Test configuration without switching
      ${prefix}update   - Update flake inputs
      ${prefix}sync     - Commit and push changes

    🛠️  Utilities:
      ${prefix}repl     - Enter Nix REPL
      ${prefix}fmt      - Format all files with treefmt
      ${prefix}check    - Run all checks (format, lint)
      ${prefix}status   - Show git status

    📚 Help:
      ${prefix}help     - Show all available commands
      ${prefix}list     - List commands with descriptions

    EOF
        fi

    #> Ensure we are at the root of the dots dir
    echo "SRC: ${src}"
    # cd "$DOTS" || true
  '';
in
  pkgs.mkShell {
    inherit (config) name;
    inherit packages env shellHook;
  }
