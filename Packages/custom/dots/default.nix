# Packages/custom/dots/default.nix
{
  pkgs,
  lib,
  api,
  system,
  all,
  ...
}: let
  name = "dotDots";
  inherit (lib.lists) findFirst head;
  inherit (lib.attrsets) attrValues listToAttrs optionalAttrs;
  inherit (pkgs) writeShellScriptBin;

  #> Get nixosConfigurations from the evaluated flake outputs
  nixosConfigurations = all.nixosConfigurations or {};

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
  host = optionalAttrs (api.hosts ? ${hostName}) api.hosts.${hostName} // {name = hostName;} // currentHost;

  #> Create the dotDots script using rust-script
  cli = writeShellScriptBin "dotDots" ''
    #!/usr/bin/env bash
    exec ${pkgs.rust-script}/bin/rust-script ${./main.rs} "$@"
  '';

  #> Create wrapper scripts for each command
  mkCmd = cmd:
    writeShellScriptBin "_${cmd}" ''
      #!/usr/bin/env bash
      exec ${cli}/bin/dotDots ${cmd} "$@"
    '';

  commands = listToAttrs (
    map
    (cmd: {
      name = "_${cmd}";
      value = mkCmd cmd;
    })
    ["hosts" "info" "rebuild" "test" "boot" "dry" "update" "clean" "list" "help"]
  );

  packages = with pkgs;
    [
      #| Core tools
      bat
      fd
      gitui
      gnused
      jq
      nil
      nixd
      onefetch
      undollar

      #| Rust toolchain (for building dots-cli)
      rustc
      cargo
      rust-analyzer
      rustfmt

      #| Clipboard dependencies
      xclip
      wl-clipboard
      xsel

      #| Formatters
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
    ++ [cli];

  env = with host.paths; {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    DOTS = dots;
    DOTS_BIN = dots + "/Bin";
    BINIT = dots + "/Bin/shellscript/base/binit";
    ENV_BIN = dots + "/.direnv/bin";
    HOST_NAME = host.name;
    HOST_TYPE = host.platform;
  };

  shellHook = ''
    #> Create directory for wrapper scripts
    mkdir -p "$ENV_BIN"

    #> Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    #> Display a welcome message
    if command -v dotDots >/dev/null 2>&1; then
      dotDots help
    else
      printf "🎯 NixOS Configuration REPL"
      printf "============================"
      printf
      printf "Current host: $HOST_NAME"
      printf "System: $HOST_TYPE"
      printf
      printf "Type '_help' for available commands"
      printf "Type '%s help' for more options\n\n" "${name}"
    fi
  '';
in
  pkgs.mkShell {inherit name packages env shellHook;}
