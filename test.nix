# repl.nix
{
  pkgs,
  lib,
  api,
  lix,
  system,
  all,
  ...
}: let
  inherit
    (lib)
    findFirst
    head
    attrValues
    attrNames
    filterAttrs
    splitString
    attrByPath
    mapAttrs
    filter
    elem
    hasPrefix
    ;

  # We need to get nixosConfigurations from the evaluated flake outputs
  nixosConfigurations = all.nixosConfigurations or {};

  # Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (attrValues nixosConfigurations);

  # Get the current host
  currentHost =
    if matchingHost != null
    then matchingHost
    else head (attrValues nixosConfigurations);

  # Create a simple REPL module that directly exposes the original repl.nix structure
  # We'll embed the original repl.nix logic but make it self-contained
  replModuleFile = pkgs.writeText "repl-module.nix" ''
    # Direct import of the original repl.nix with all dependencies
    let
      # Import the original repl.nix with all its arguments
      originalRepl = import ${toString ./repl.nix} {
        inherit pkgs lib api lix system;
        all = builtins.getFlake (toString ./.);
      };
    in
    originalRepl
  '';
in
  pkgs.mkShell {
    name = "nixos-config-repl";

    packages = with pkgs; [
      jq
      nixpkgs-fmt
      nil
      nixd
      alejandra
      # nix-repl
      # nix
    ];

    shellHook = ''
      # Create directory for wrapper scripts
      WRAPPER_DIR="$PWD/.direnv/bin"
      mkdir -p "$WRAPPER_DIR"

      # nixos-repl: loads the original repl.nix file directly
      cat > "$WRAPPER_DIR/nixos-repl" << 'EOF'
      #!/usr/bin/env bash
      export NIX_CONFIG="experimental-features = nix-command flakes"
      # Load the original repl.nix file
      exec nix repl --impure ${toString ./repl.nix} "$@"
      EOF

      # repl: simple wrapper for nix-repl (matches your original)
      cat > "$WRAPPER_DIR/repl" << 'EOF'
      #!/bin/sh
      exec nix-repl "$@"
      EOF

      # Helper to list hosts - using nix eval directly
      cat > "$WRAPPER_DIR/h-hosts" << 'EOF'
      #!/usr/bin/env bash
      export NIX_CONFIG="experimental-features = nix-command flakes"
      # Use nix eval with the original repl.nix structure
      nix eval --impure --expr '
        let
          repl = import ${toString ./repl.nix} {
            pkgs = import <nixpkgs> {};
            lib = (import <nixpkgs> {}).lib;
            api = {};
            lix = {};
            system = builtins.currentSystem;
            all = builtins.getFlake (toString ./.);
          };
        in
        repl.helpers.listHosts
      ' --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[]' 2>/dev/null || \
      nix eval --impure --expr 'builtins.attrNames (builtins.getFlake (toString ./.)).nixosConfigurations' --json | ${pkgs.jq}/bin/jq -r '.[]'
      EOF

      # Helper to show host info - simplified without jq dependency in path
      cat > "$WRAPPER_DIR/h-info" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      export NIX_CONFIG="experimental-features = nix-command flakes"
      # Try to use the full repl structure first, fallback to simple version
      nix eval --impure --expr '
        let
          flake = builtins.getFlake (toString ./.);
          hostConfig = flake.nixosConfigurations."'"$host"'";
        in {
          hostname = hostConfig.config.networking.hostName;
          system = hostConfig.config.nixpkgs.hostPlatform.system;
          kernel = hostConfig.config.boot.kernelPackages.kernel.version;
          stateVersion = hostConfig.config.system.stateVersion;
        }
      ' --json 2>/dev/null | ${pkgs.jq}/bin/jq . 2>/dev/null || \
      echo "{\"hostname\": \"$host\", \"error\": \"Could not load host configuration\"}"
      EOF

      # Helper to rebuild a host
      cat > "$WRAPPER_DIR/h-rebuild" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild switch --flake .#%s\n" "$host"
      EOF

      # Helper to test a host
      cat > "$WRAPPER_DIR/h-test" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild test --flake .#%s\n" "$host"
      EOF

      # Helper for boot
      cat > "$WRAPPER_DIR/h-boot" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild boot --flake .#%s\n" "$host"
      EOF

      # Helper for dry build
      cat > "$WRAPPER_DIR/h-dry" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild dry-build --flake .#%s\n" "$host"
      EOF

      # Helper for update
      cat > "$WRAPPER_DIR/h-update" << 'EOF'
      #!/usr/bin/env bash
      printf "nix flake update\n"
      EOF

      # Helper for cleanup
      cat > "$WRAPPER_DIR/h-clean" << 'EOF'
      #!/usr/bin/env bash
      printf "sudo nix-collect-garbage -d\n"
      EOF

      # Helper for listing all helpers
      cat > "$WRAPPER_DIR/h-list" << 'EOF'
      #!/usr/bin/env bash
      printf "\033[1;36m#~@ Available helpers\033[0m\n"
      printf "  \033[1;32mh-hosts\033[0m             - List all hosts\n"
      printf "  \033[1;32mh-info [host]\033[0m       - Show host info\n"
      printf "  \033[1;32mh-rebuild [host]\033[0m    - Rebuild command\n"
      printf "  \033[1;32mh-test [host]\033[0m       - Test command\n"
      printf "  \033[1;32mh-boot [host]\033[0m       - Boot command\n"
      printf "  \033[1;32mh-dry [host]\033[0m        - Dry build command\n"
      printf "  \033[1;32mh-update\033[0m            - Update flake\n"
      printf "  \033[1;32mh-clean\033[0m             - Clean garbage\n"
      printf "  \033[1;32mnixos-repl\033[0m          - Start Nix REPL with original repl.nix\n"
      printf "  \033[1;32mrepl\033[0m                - Start nix-repl\n"
      printf "\n"
      printf "\033[1;36m#~@ Quick usage\033[0m\n"
      printf "  Most helpers accept an optional host argument. Default: \033[1;33m${currentHost.config.networking.hostName}\033[0m\n"
      EOF

      # Helper for REPL help
      cat > "$WRAPPER_DIR/repl-help" << 'EOF'
      #!/usr/bin/env bash
      printf "\033[1;36m#> NixOS Configuration REPL\033[0m\n"
      printf "\033[1;36m#> Current context:\033[0m\n"
      printf "  Host: \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
      printf "  System: \033[1;32m${system}\033[0m\n"
      printf "\n"
      printf "\033[1;36m#> Available commands:\033[0m\n"
      printf "  h-list             - Show all helpers\n"
      printf "  h-hosts            - List all configured hosts\n"
      printf "  h-info [host]      - Show host information\n"
      printf "  nixos-repl         - Start REPL with original repl.nix\n"
      printf "  repl               - Start nix-repl\n"
      printf "\n"
      printf "\033[1;36m#> In nixos-repl you can access:\033[0m\n"
      printf "  config.*           - Current host configuration\n"
      printf "  helpers.*          - Helper functions\n"
      printf "  pkgs               - Current host packages\n"
      printf "  boot.*             - Boot configuration\n"
      printf "  networking.*       - Network configuration\n"
      printf "  services.*         - Services configuration\n"
      EOF

      # Make scripts executable
      chmod +x "$WRAPPER_DIR"/*
      export PATH="$WRAPPER_DIR:$PATH"

      # Show welcome message
      printf "\033[1;36m🎯 NixOS Configuration REPL\033[0m\n"
      printf "\033[1;30m============================\033[0m\n\n"
      printf "\033[1;33mCurrent host:\033[0m \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
      printf "\033[1;33mSystem:\033[0m \033[1;32m${system}\033[0m\n\n"
      printf "Type \033[1;32mh-list\033[0m for available helpers\n"
      printf "Type \033[1;32mnixos-repl\033[0m to start Nix REPL with your configuration\n"
      printf "Type \033[1;32mrepl\033[0m to start nix-repl\n\n"
    '';
  }
