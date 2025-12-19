# Packages/custom/dots/default.nix
{
  pkgs,
  lib,
  api,
  system,
  all,
  ...
}: let
  inherit (lib.lists) findFirst head;
  inherit (lib.attrsets) attrValues optionalAttrs;

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
  host =
    (optionalAttrs (api.hosts ? ${hostName}) api.hosts.${hostName})
    // {
      name = hostName;
      config = currentHost.config;
      options = currentHost.options;
      pkgs = currentHost.pkgs;
      platform = currentHost.config.nixpkgs.hostPlatform.system;
      paths = {
        dots = builtins.toString ./.;
      };
    };

  #> Build the Rust binary
  dotsCli = pkgs.rustPlatform.buildRustPackage {
    pname = "dots-cli";
    version = "0.1.0";
    src = ./.; # Assuming this directory contains Cargo.toml and src/

    cargoSha256 = pkgs.lib.fakeSha256; # You'll need to update this after first build

    # Or use cargoLock if you have Cargo.lock:
    # cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = with pkgs; [pkg-config];
    buildInputs = with pkgs; [
      # Clipboard dependencies
      xorg.libxcb
      libxkbcommon
      wayland
    ];

    meta = with lib; {
      description = "NixOS Configuration Management CLI";
      license = licenses.mit;
    };
  };

  #> Create wrapper scripts for each command
  makeDotCommand = cmd:
    pkgs.writeShellScriptBin "_${cmd}" ''
      exec ${dotsCli}/bin/dots ${cmd} "$@"
    '';

  dotCommands = builtins.listToAttrs (
    map
    (cmd: {
      name = "_${cmd}";
      value = makeDotCommand cmd;
    })
    ["hosts" "info" "rebuild" "test" "boot" "dry" "update" "clean" "list" "help"]
  );

  name = "dotDots";
  packages = (import ./pkgs.nix {inherit pkgs;}) ++ (builtins.attrValues dotCommands) ++ [dotsCli];
  env = import ./vars.nix {inherit host;};

  shellHook = ''
    # Create directory for wrapper scripts
    mkdir -p "$ENV_BIN"

    # Add bin directory to PATH
    export PATH="$ENV_BIN:$PATH"

    # Welcome message
    if command -v dots >/dev/null 2>&1; then
      dots help
    else
      echo "🎯 NixOS Configuration REPL"
      echo "============================"
      echo
      echo "Current host: $HOST_NAME"
      echo "System: $HOST_PLATFORM"
      echo
      echo "Type '_help' for available commands"
      echo
    fi
  '';
in
  pkgs.mkShell {
    inherit name packages env shellHook;

    # Additional environment variables
  }
