{
  lib,
  lix,
  system,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues filterAttrs mapAttrsToList;
  inherit (lib.lists) foldl';
  inherit (lib.strings) concatStrings concatMapStringsSep genList stringLength;
  inherit (lix) mkShellApp;

  #──────────────────────────────────────────────────────────────────────────────
  # Configuration
  #──────────────────────────────────────────────────────────────────────────────

  config = {
    name = "dots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
  };

  #──────────────────────────────────────────────────────────────────────────────
  # CLI Tools
  #──────────────────────────────────────────────────────────────────────────────

  commands = {
    ${config.name} = {
      inputs = with pkgs; [rust-script gcc rustfmt];
      command = ''exec "$DOTS/Bin/rust/.dots.rs" "$@"'';
      description = "Main dotfiles management CLI";
      aliases = [
        {
          name = "hosts";
          description = "List available hosts";
        }
        {
          name = "info";
          description = "Show system information";
        }
        {
          name = "rebuild";
          description = "Rebuild NixOS configuration";
        }
        {
          name = "test";
          description = "Test configuration without switching";
        }
        {
          name = "boot";
          description = "Build configuration for next boot";
        }
        {
          name = "dry";
          description = "Dry run rebuild";
        }
        {
          name = "update";
          description = "Update flake inputs";
        }
        {
          name = "clean";
          description = "Clean old generations";
        }
        {
          name = "sync";
          description = "Commit and push changes";
        }
        {
          name = "binit";
          description = "Initialize bin directories";
        }
        {
          name = "list";
          description = "List all available commands";
        }
        {
          name = "help";
          description = "Show help information";
        }
      ];
    };

    repl = {
      inputs = [];
      command = ''exec nix repl --file "$DOTS/default.nix"'';
      description = "Enter Nix REPL with dotfiles loaded";
    };

    fmt = {
      inputs = with pkgs; [treefmt];
      command = ''
        printf "🎨 Formatting all files with treefmt...\n"
        cd "$DOTS" || exit 1
        exec treefmt "$@"
      '';
      description = "Format all files with treefmt";
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
      description = "Run all checks (format, lint)";
    };

    status = {
      inputs = with pkgs; [git];
      command = ''
        #> Initialize/Parse arguments
        prompt_mode=false
        while [ $# -gt 0 ]; do
          case "$1" in
            --prompt | -p)
              prompt_mode=true
              shift
              ;;
            --help | -h)
              printf "Usage: status [OPTIONS]\n"
              printf "\nOptions:\n"
              printf "  --prompt, -p    Output minimal format for prompt\n"
              printf "  --help, -h      Show this help message\n"
              exit 0
              ;;
            *)
              printf "Unknown option: %s\n" "$1" >&2
              printf "Use --help for usage information\n" >&2
              exit 1
              ;;
          esac
        done

        #? Check if we're in a git repository
        if [ -d "$DOTS/.git" ]; then :; else
          case "$prompt_mode" in
            true | 1)
              exit 0 ;;
            *)
              printf "⚠️  Not a git repository\n"
              exit 1
            ;;
          esac
        fi

        #> Get branch information
        branch=$(git -C "$DOTS" branch --show-current 2>/dev/null)

        #> Get change count
        changes=$(git -C "$DOTS" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        #> Print the status
        case "$prompt_mode" in
          true | 1)
            #~@ Prompt mode: minimal output for PS1
            if [ "$changes" -gt 0 ]; then
              printf "[%s +%s]" "$branch" "$changes"
            else
              printf "[%s]" "$branch"
            fi
            exit 0
            ;;
          *)
            #~@ Full status mode
            printf "📊 Repository Status\n"
            printf "====================\n\n"

            printf "📍  Branch: %s\n" "$branch"

            if [ "$changes" -gt 0 ]; then
              printf "📝 Changes: %s uncommitted\n" "$changes"
              git -C "$DOTS" status --short
            else
              printf "✨ Working tree clean\n"
            fi
          ;;
        esac
      '';
      description = "Show git repository status";
    };
  };

  #> Generate applications from commands using mkShellApp
  applications = let
    #> Merge all app into attrsets from mkShellApp
    mergeApps = foldl' (acc: apps: acc // apps) {};

    #> Convert commands to mkShellApp calls
    allApps =
      mapAttrsToList (
        name: cfg:
          mkShellApp {
            inherit (cfg) command description;
            name = name;
            prefix = cfg.prefix or config.prefix;
            inputs = cfg.inputs or [];
            aliases = cfg.aliases or [];
          }
      )
      commands;
  in
    mergeApps allApps;

  #> Generate command list for shellHook
  commandList = with config; let
    mainCmd = commands.${name};

    #> Collect all commands with their names and descriptions
    allCommands =
      #~@ Main command aliases
      (map (a: {
        name = "${prefix}${a.name}";
        description = a.description;
      }) (mainCmd.aliases or []))
      ++
      #~@ Other standalone commands
      (mapAttrsToList (name: cfg: {
        name = "${prefix}${name}";
        description = cfg.description;
      }) (filterAttrs (cmd: _: cmd != name) commands));

    #> Find the longest command name for alignment
    maxNameLength =
      foldl' (
        max: cmd: let
          len = stringLength cmd.name;
        in
          if len > max
          then len
          else max
      )
      0
      allCommands;

    #> Format each command with proper padding
    formatCmd = cmd: let
      padding = maxNameLength - (stringLength cmd.name);
      spaces = concatStrings (genList (_: " ") padding);
    in "  ${cmd.name}${spaces}  - ${cmd.description}";
  in
    concatMapStringsSep "\n" formatCmd allCommands;

  #──────────────────────────────────────────────────────────────────────────────
  # Packages
  #──────────────────────────────────────────────────────────────────────────────

  packages =
    (attrValues applications)
    ++ (with pkgs;
      [
        #~@ Rust
        rustc
        cargo
        rust-analyzer
        rustfmt
        rust-script
        gcc
        clippy
      ]
      ++ [
        #~@ Formatters
        alejandra
        deno
        markdownlint-cli2
        nixfmt
        nufmt
        shellcheck
        shfmt
        stylua
        taplo
        treefmt
        typstyle
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
        actionlint
        bat
        busybox
        direnv
        eza
        fd
        gitui
        gnused
        jq
        mise
        mpv
        nil
        nix-output-monitor
        nix-tree
        nixd
        nushell
        onefetch
        ripgrep
        tokei
        undollar
        watchexec
        yazi
      ]);

  #──────────────────────────────────────────────────────────────────────────────
  # Shell Configuration
  #──────────────────────────────────────────────────────────────────────────────

  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = "$(hostname)";
  };

  shellHook = with config; ''
    #> Dynamically determine host info
    export HOSTNAME="$(hostname)"
    export HOSTTYPE="${system}"

    #> Set up cache directory structure
    export DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${cache}"}"
    export ENV_BIN="$DOTS_CACHE/bin"
    export DOTS_LOGS="$DOTS_CACHE/logs"
    export DOTS_TMP="$DOTS_CACHE/tmp"
    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Color output support
    export CLICOLOR=1

    #> Initialize bin directories
    if command -v ${prefix}${name} >/dev/null 2>&1; then
      eval "$(${prefix}${name} binit 2>/dev/null || true)" 2>/dev/null || true
    fi

    #> Check for direnv
    if command -v direnv >/dev/null 2>&1 && [ -f "$DOTS/.envrc" ]; then
      eval "$(direnv hook bash 2>/dev/null)" 2>/dev/null || true
    fi

    #> Use starship for prompt
    if command -v starship >/dev/null 2>&1; then
      eval "$(starship init bash)"
    fi

    #> Display welcome message
    printf '╔═══════════════════════════════════════════════════════╗\n'
    printf '║               dotDots Configuration Shell             ║\n'
    printf '╚═══════════════════════════════════════════════════════╝\n'
    printf "%s\n" "${commandList}"
    printf "\n  Run %shelp for detailed help information\n\n" "${prefix}"
  '';
in
  pkgs.mkShell (with config; {
    inherit name packages env shellHook;
  })
