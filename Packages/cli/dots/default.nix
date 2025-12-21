# Packages/custom/dots/default.nix
{
  self,
  pkgs,
  system,
  lib,
  hosts,
  ...
}: let
  name = "dotDots";
  inherit (lib.lists) findFirst head;
  inherit (lib.attrsets) attrValues listToAttrs optionalAttrs;
  inherit (pkgs) writeShellScriptBin;

  #> Get nixosConfigurations from the evaluated flake outputs
  nixosConfigurations = self.nixosConfigurations or {};

  #> Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (attrValues nixosConfigurations);

  #> Get the current host
  currentHost =
    if matchingHost != null
    then matchingHost
    else head (attrValues nixosConfigurations);

  inherit (currentHost.config.networking) hostName;

  #> Create enhanced host info using optionalAttrs
  host = optionalAttrs (hosts ? ${hostName}) hosts.${hostName} // {name = hostName;} // currentHost;

  #> Create the dotDots script using rust-script
  rustScript = writeShellScriptBin "dotDots" ''
    #!/usr/bin/env bash
    exec ${pkgs.rust-script}/bin/rust-script ${./main.rs} "$@"
  '';

  #> Create REPL command
  replCmd = writeShellScriptBin ".repl" ''
    #!/usr/bin/env bash
    exec nix repl --file $DOTS_REPL
  '';

  #> Create wrapper scripts for each command
  mkCmd = cmd:
    writeShellScriptBin ".${cmd}" ''
      #!/usr/bin/env bash
      exec ${rustScript}/bin/dotDots ${cmd} "$@"
    '';

  commands =
    listToAttrs (
      map
      (cmd: {
        name = ".${cmd}";
        value = mkCmd cmd;
      })
      [
        #~@ Core commands
        "hosts"
        "info"
        "rebuild"
        "test"
        "boot"
        "dry"
        "update"
        "clean"
        "list"
        "help"
        "binit"
      ]
    )
    // {
      ".repl" = replCmd;
    };

  packages = with pkgs;
    [
      #~@ Core tools
      bat #? cat clone with syntax highlighting
      fd #? fast alternative to 'find'
      gitui #? TUI interface for git
      gnused #? GNU sed for text processing
      jq #? JSON processor and query tool
      nil #? Nix language server
      nixd #? Alternative Nix language server
      onefetch #? Git repo info viewer (instant project summary)
      tokei #? Counts lines of code per language
      undollar #? Replaces shell variable placeholders easily
      yazi #? TUI file manager with vim-like controls

      #~@ Git tools
      gh #? GitHub CLI for authentication switching

      #~@ Rust toolchain (for building dots-cli)
      rustc #? Rust compiler
      cargo #? Rust package manager and build system
      rust-analyzer #? Rust language server (LSP)
      rustfmt #? Rust code formatter

      #~@ Clipboard dependencies
      xclip #? Clipboard utility for X11
      wl-clipboard #? Clipboard utility for Wayland
      xsel #? Another X11 clipboard interaction tool

      #~@ Formatters
      alejandra #? Nix code formatter
      markdownlint-cli2 #? Markdown linter and style checker
      nixfmt #? Alternative Nix formatter
      shellcheck #? Linter for shell scripts
      shfmt #? Shell script formatter
      taplo #? TOML formatter and linter
      treefmt #? Unified formatting tool for multiple languages
      yamlfmt #? YAML formatter
    ]
    ++ (attrValues commands)
    ++ [rustScript];

  env = with host.paths; {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    DOTS = dots;
    DOTS_REPL = dots + "/repl.nix";
    DOTS_BIN = dots + "/Bin";
    ENV_BIN = dots + "/.direnv/bin";
    HOST_NAME = host.name;
    HOST_TYPE = host.platform;
  };

  shellHook = ''
    #> Create directory for wrapper scripts
    mkdir -p "$ENV_BIN"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Initialize bin directories
    if command -v dotDots >/dev/null 2>&1; then
      # Silently eval binit to add all bin directories to PATH
      eval "$(dotDots binit)" 2>/dev/null || true
    fi

    #> Display a welcome message
    if command -v dotDots >/dev/null 2>&1; then
      dotDots help
    else
      printf "🎯 NixOS Configuration REPL\n"
      printf "============================\n"
      printf "\n"
      printf "Current host: $HOST_NAME\n"
      printf "System: $HOST_TYPE\n"
      printf "\n"
      printf "Type '.help' for available commands\n"
      printf "Type 'dotDots help' for more options\n"
      printf "Type '.sync [message]' to commit & push all changes (submodule + dotDots)\n\n"
    fi
  '';
in
  pkgs.mkShell {inherit name packages env shellHook;}
