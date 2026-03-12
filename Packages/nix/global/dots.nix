{
  lib,
  lix,
  system,
  pkgs,
  fmtPackages ? [],
  mediaPackages ? [],
  ...
}: let
  inherit (lib.attrsets) attrValues mapAttrsToList;
  inherit (lib.lists) filter foldl' optionals;
  inherit (lib.strings) concatStrings concatMapStringsSep genList stringLength;
  inherit (lix) mkShellApp;
  inherit (pkgs.stdenv) isLinux;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Configuration                                                               |
  #|─────────────────────────────────────────────────────────────────────────────|

  config = {
    name = "dots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
  };

  #|─────────────────────────────────────────────────────────────────────────────|
  #| CLI Tools                                                                   |
  #|─────────────────────────────────────────────────────────────────────────────|

  commands.${config.name} = {
    command = ''rust-script "$DOTS/Bin/rust/.dots.rs" "$@"'';
    description = "Main dotfiles management CLI";
    aliases = [
      #~@ System/Info
      {
        name = "info";
        description = "Show system information";
      }
      {
        name = "hosts";
        description = "List available hosts";
      }

      #~@ Build/Rebuild
      {
        name = "boot";
        description = "Build configuration for next boot";
      }
      {
        name = "dry";
        description = "Dry run rebuild";
      }
      {
        name = "rebuild";
        description = "Rebuild NixOS configuration";
      }
      {
        name = "check";
        description = "Run all checks, including code quality";
      }
      {
        name = "fmt";
        description = "Format the project tree";
      }

      #~@ Maintenance/Utilities
      {
        name = "clean";
        description = "Clean old generations";
      }
      {
        name = "list";
        description = "List all available commands";
      }
      {
        name = "help";
        description = "Show help information";
      }

      #~@ Interaction/REPL
      {
        name = "repl";
        description = "Enter Nix REPL";
      }

      #~@ Discovery/Search
      {
        name = "search";
        description = "Search for patterns";
      }

      #~@ Version Control/Update
      {
        name = "update";
        description = "Update flake inputs";
      }
      {
        name = "sync";
        description = "Commit and push changes";
      }
      {
        name = "status";
        description = "Show repository status";
      }
      {
        name = "binit";
        description = "Initialize bin directories";
      }
    ];
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
            inherit pkgs;
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

    #> Group aliases by domain
    groups = [
      {
        name = "System/Info";
        aliases = ["info" "hosts"];
      }
      {
        name = "Build/Rebuild";
        aliases = ["boot" "dry" "rebuild" "check" "fmt"];
      }
      {
        name = "Maintenance/Utilities";
        aliases = ["clean" "list" "help"];
      }
      {
        name = "Interaction/REPL";
        aliases = ["repl"];
      }
      {
        name = "Discovery/Search";
        aliases = ["search"];
      }
      {
        name = "Version Control/Update";
        aliases = [
          "update"
          "sync"
          "status"
          # "binit"
        ];
      }
    ];

    #> Flatten and add headers
    allCommands =
      concatMapStringsSep "\n" (
        group: let
          header = "\n${group.name}:\n";
          #> Filter aliases by group
          cmds = filter (a: builtins.elem a.name group.aliases) (mainCmd.aliases or []);
          #> Format each command
          maxNameLength =
            foldl' (
              max: cmd: let
                len = stringLength "${prefix}${cmd.name}";
              in
                if len > max
                then len
                else max
            )
            0
            cmds;
          formatCmd = cmd: let
            padding = maxNameLength - (stringLength "${prefix}${cmd.name}");
            spaces = concatStrings (genList (_: " ") padding);
          in "  ${prefix}${cmd.name}${spaces}  - ${cmd.description}";
        in
          if cmds != []
          then header + concatMapStringsSep "\n" formatCmd cmds
          else ""
      )
      groups;
  in
    allCommands;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Packages                                                                    |
  #|─────────────────────────────────────────────────────────────────────────────|

  packages = with pkgs;
    [
      bat #? Cat clone with syntax highlighting
      cargo #? Rust package manager
      direnv #? Environment management per directory
      dos2unix #? Line ending converter
      eza #? Modern ls replacement
      fd #? Fast find alternative
      gcc #? GNU C compiler
      gitui #? Git terminal UI
      gnused #? GNU stream editor
      imagemagick #? Image processing
      jq #? JSON query processor
      lsd #? LSDeluxe file lister
      mise #? Polyglot version manager
      mtr #? Network diagnostic tool
      nil #? Nix language server
      nitch #? System fetch written in nim
      nix-output-monitor #? Build output monitor
      nix-tree #? Nix dependency visualizer
      nixd #? Nix language daemon
      nushell #? Modern shell language
      onefetch #? Git repository summary
      pandoc #? Universal document converter
      poppler-utils #? PDF utilities (pdfunite, pdfseparate)
      qpdf #? PDF transformation
      ripgrep #? Fast grep alternative
      rust-script #? Rust scripting
      rustc #? Rust compiler
      starship #? Cross-shell prompt
      tldr #? Simplified man pages
      tokei #? Code statistics tool
      typst #? Modern LaTeX alternative
      undollar #? Remove leading dollar signs
      watchexec #? File watcher and executor
      yazi #? Terminal file manager
      zoxide #? Smart cd replacement
    ]
    ++ (attrValues applications)
    ++ fmtPackages #? From fmt.nix: treefmt, alejandra, etc.
    ++ mediaPackages #? From media.nix: mpv, ffmpeg, yt-dlp, etc.
    ++ (optionals isLinux [xclip wl-clipboard xsel]); #? Linux clipboard tools

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Shell Configuration                                                         |
  #|─────────────────────────────────────────────────────────────────────────────|
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = "$(hostname)";
  };

  shellHook = with config; ''
    #> Determine host info dynamically
    HOSTNAME="$(hostname)"
    HOSTTYPE="${system}"
    export HOSTNAME HOSTTYPE

    #> Ensure DOTS is setand available for use
    DOTS="$(pwd -P)"
    [ -s "$DOTS_LIB_SH" ] || DOTS_LIB_SH="$DOTS/Libraries/shellscript"
    export DOTS DOTS_LIB_SH

    #> Set up cache directory structure
    DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${cache}"}"
    ENV_BIN="$DOTS_CACHE/bin"
    DOTS_LOGS="$DOTS_CACHE/logs"
    DOTS_TMP="$DOTS_CACHE/tmp"
    mkdir -p "$ENV_BIN" "$DOTS_LOGS" "$DOTS_TMP"
    export DOTS_CACHE DOTS_LOGS DOTS_TMP

    #> Add bin directory to PATH
    case ":$PATH:" in
      *":$ENV_BIN:"*) ;;
      *) PATH="$ENV_BIN:$PATH" ;;
    esac
    export PATH

    #> Initialize bin directories with binit if available
    BINIT_PATH="$DOTS_LIB_SH/base/binit"
    if [ -f "''${BINIT_PATH:-}" ]; then
      if [ -x "$BINIT_PATH" ]; then :; else chmod +x "$BINIT_PATH"; fi
      . "$BINIT_PATH"
    else
      printf "direnv: binit not found at %s\n" "''${BINIT_PATH}" >&2
    fi

    #> Use starship for prompt
    if command -v starship >/dev/null 2>&1; then
      STARSHIP_CONFIG="$DOTS/Configuration/starship/config.toml"
      export STARSHIP_CONFIG
      eval "$(starship init bash)"
    fi

    #> Display repository summary with onefetch if in a git repository
    if [ -d .git ] && command -v onefetch >/dev/null 2>&1; then
      onefetch \
      --no-art \
      --no-title \
      --no-color-palette \
      --nerd-fonts \
      --number-separator comma \
      --disabled-fields 'project' 'description' 'head' 'version' 'created' 'languages' 'dependencies' 'authors' 'contributors' 'url' 'churn' 'license'
    fi

    #> Display shell information with nitch
    if command -v nitch >/dev/null 2>&1; then
      nitch
    fi

    #> Display welcome message
    printf '╔═══════════════════════════════════════════════════════╗\n'
    printf '║               dotDots Configuration Shell             ║\n'
    printf '╚═══════════════════════════════════════════════════════╝\n'
    printf "%s\n\n" "${commandList}"
    printf "  Run %shelp for detailed help information\n\n" "${prefix}"
  '';
in
  pkgs.mkShell (with config; {
    inherit name packages env shellHook;
  })
