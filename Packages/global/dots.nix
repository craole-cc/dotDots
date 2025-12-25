{
  lib,
  lix,
  system,
  pkgs,
  formatters ? [],
  ...
}: let
  inherit (lib.attrsets) attrValues mapAttrsToList;
  inherit (lib.lists) filter foldl';
  inherit (lib.strings) concatStrings concatMapStringsSep genList stringLength;
  inherit (lix) mkShellApp;

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

  commands = {
    ${config.name} = {
      inputs = with pkgs; [rust-script gcc rustfmt];
      command = ''exec "$DOTS/Bin/rust/.dots.rs" "$@"'';
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

  packages =
    (attrValues applications)
    ++ formatters
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
        #~@ Clipboard
        xclip
        wl-clipboard
        xsel
      ]
      ++ [
        #~@ Utilities
        actionlint
        bat
        dos2unix
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

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Shell Configuration                                                         |
  #|─────────────────────────────────────────────────────────────────────────────|
  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    SYSTEM = "$(hostname)";
  };

  shellHook = with config; ''
    #> Determine host info dynamically
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

    #> Use starship for prompt
    export STARSHIP_CONFIG="$DOTS/Configuration/starship/config.toml"
    eval "$(starship init bash)"

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
