{
  lib,
  src,
  system,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) listToAttrs attrValues;
  inherit (pkgs) writeShellScriptBin;

  #──────────────────────────────────────────────────────────────────────────────
  # CLI Tools
  #──────────────────────────────────────────────────────────────────────────────

  # Create the main dotDots script using rust-script
  rustScript = writeShellScriptBin "dotDots" ''
    #!/usr/bin/env bash
    exec ${pkgs.rust-script}/bin/rust-script ${src + "/Bin/rust/.dots.rs"} "$@"
  '';

  # Create REPL command
  replCmd = writeShellScriptBin ".repl" ''
    #!/usr/bin/env bash
    exec nix repl --file ${toString src}/default.nix
  '';

  # Create wrapper scripts for each command
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
        "sync"
        "binit"
        "list"
        "help"

        #~@ Workflow commands
        "flick"
        "flush"
        "fmt"
        "fo"
        "ff"
        "flow"
        "flare"
        "ft"
      ]
    )
    // {".repl" = replCmd;};

  packages = with pkgs;
    [
      #~@ Core tools
      bat
      fd
      gitui
      gnused
      jq
      nil
      nixd
      onefetch
      tokei
      undollar
      yazi

      #~@ Git tools
      gh

      #~@ Rust toolchain
      rustc
      cargo
      rust-analyzer
      rustfmt
      rust-script

      #~@ Clipboard dependencies
      xclip
      wl-clipboard
      xsel

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
    ++ (attrValues commands)
    ++ [rustScript];

  env = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    DOTS = toString src;
    DOTS_BIN = toString (src + "/Bin");
  };

  shellHook = ''
    #> Override DOTS to point to actual repository, not Nix store
    export DOTS="$PWD"
    export DOTS_BIN="$DOTS/Bin"

    #> Dynamically determine host info
    export HOST_NAME="$(hostname)"
    export HOST_TYPE="${system}"

    #> Set up cache directory
    export DOTS_CACHE="''${DOTS_CACHE:-"$DOTS/.cache"}"
    export ENV_BIN="$DOTS_CACHE/bin"
    mkdir -p "$ENV_BIN"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Initialize bin directories
    if command -v dotDots >/dev/null 2>&1; then
      eval "$(dotDots binit 2>/dev/null || true)" 2>/dev/null || true
    fi

    #> Display welcome message
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
      printf "Type '.repl' to enter Nix REPL\n"
      printf "Type '.sync [message]' to commit & push all changes\n\n"
    fi
  '';
in
  pkgs.mkShell {
    name = "dotDots";
    inherit packages env shellHook;
  }
