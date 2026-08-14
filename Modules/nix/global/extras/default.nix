args: let
  description = "Exhaustive Shell";
  inherit
    (args)
    cfg
    formatters
    lix
    system
    pkgs
    pkgsFor
    inputs
    ;
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.selection) filterAttrs;
  inherit (lix.attrsets.transformation) mapAttrsToList;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.construction) genList;
  inherit (lix.strings.access) stringLength;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.strings.construction) concatStrings concatMapStringsSep;
  inherit (lix.applications.construction) mkShellApp;

  #|---------------------------------------------------------|
  #| CLI Tools ----------------------------------------------|
  #|---------------------------------------------------------|
  commands.${cfg.name} = {
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
        name: spec:
          mkShellApp {
            inherit pkgs;
            inherit (spec) command description;
            inherit name;
            prefix = spec.prefix or cfg.prefix;
            inputs = spec.inputs or [];
            aliases = spec.aliases or [];
          }
      )
      commands;
  in
    mergeApps allApps;

  #> Generate command list for shellHook
  commandList = let
    mainCmd = commands.${cfg.name};

    #> Group aliases by domain
    groups = [
      {
        name = "System/Info";
        aliases = [
          "info"
          "hosts"
        ];
      }
      {
        name = "Build/Rebuild";
        aliases = [
          "boot"
          "dry"
          "rebuild"
          "check"
          "fmt"
        ];
      }
      {
        name = "Maintenance/Utilities";
        aliases = [
          "clean"
          "list"
          "help"
        ];
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
                len = stringLength "${cfg.prefix}${cmd.name}";
              in
                if len > max
                then len
                else max
            )
            0
            cmds;
          formatCmd = cmd: let
            padding = maxNameLength - (stringLength "${cfg.prefix}${cmd.name}");
            spaces = concatStrings (genList (_: " ") padding);
          in "  ${cfg.prefix}${cmd.name}${spaces}  - ${cmd.description}";
        in
          if cmds != []
          then header + concatMapStringsSep "\n" formatCmd cmds
          else ""
      )
      groups;
  in
    allCommands;

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages =
    (with pkgs; [
      cargo # ? Rust package manager
      dos2unix # ? Line ending converter
      eza # ? Modern ls replacement
      gcc # ? GNU C compiler
      gitui # ? Git terminal UI
      imagemagick # ? Image processing
      mise # ? Polyglot version manager
      mtr # ? Network diagnostic tool
      nil # ? Nix language server
      nix-output-monitor # ? Build output monitor
      nix-tree # ? Nix dependency visualizer
      nushell # ? Modern shell language
      pandoc # ? Universal document converter
      poppler-utils # ? PDF utilities (pdfunite, pdfseparate)
      qpdf # ? PDF transformation
      rust-script # ? Rust scripting
      rustc # ? Rust compiler
      starship # ? Cross-shell prompt
      statix # ? Lints and suggestions for nix
      tldr # ? Simplified man pages
      tokei # ? Code statistics tool
      typst # ? Modern LaTeX alternative
      watchexec # ? File watcher and executor
      yazi # ? Terminal file manager
      zoxide # ? Smart cd replacement
    ])
    ++ (pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
        opencode = "llm-agents";
      };
      # exclude = ["hermes-desktop"];
    }).packages
    ++ formatters
    ++ (attrValues applications);

  #|---------------------------------------------------------|
  #| Shell Configuration ------------------------------------|
  #|---------------------------------------------------------|
  env = {
    # NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = system;
  };

  shellHook = ''
    #> Determine host info dynamically
    HOST_NAME="$(hostname)"
    HOST_TYPE="${system}"
    export HOST_NAME HOST_TYPE

    #> Ensure DOTS is setand available for use
    DOTS="$(pwd -P)"
    [ -s "$DOTS_LIB_SH" ] || DOTS_LIB_SH="$DOTS/Libraries/shellscript"
    export DOTS DOTS_LIB_SH

    #> Set up cache directory structure
    DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/${cfg.cache}"}"
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
    printf "  Run %shelp for detailed help information\n\n" "${cfg.prefix}"
  '';
in {inherit description packages env shellHook;}
