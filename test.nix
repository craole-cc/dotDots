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
  # Since 'all' is the evaluated flake outputs (from the flake.nix call)
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

  # The original repl.nix content as a module
  replModuleContent = let
    inherit (all) nixosConfigurations;
    inherit
      (lib.attrsets)
      attrByPath
      attrNames
      attrValues
      filterAttrs
      head
      ;
    inherit
      (lib.lists)
      findFirst
      filter
      splitString
      elem
      ;
  in ''
    let
      nixosConfigurations = ${builtins.toJSON nixosConfigurations};

      # Find a host that matches current system
      matchingHost =
        lib.findFirst
        (host: host.config.nixpkgs.hostPlatform.system or null == system)
        null
        (lib.attrValues nixosConfigurations);

      # Helper functions for the repl
      helpers = {
        #~@ Script generators (copy-paste ready)
        scripts = {
          rebuild = host: "sudo nixos-rebuild switch --flake .#''${host}";
          test = host: "sudo nixos-rebuild test --flake .#''${host}";
          boot = host: "sudo nixos-rebuild boot --flake .#''${host}";
          dry = host: "sudo nixos-rebuild dry-build --flake .#''${host}";
          update = "nix flake update";
          clean = "sudo nix-collect-garbage -d";
        };

        #~@ Host discovery
        listHosts = builtins.attrNames nixosConfigurations;
        getHost = name: nixosConfigurations.''${name} or null;

        #~@ Current context
        currentHostName = currentHost.config.networking.hostName;

        #~@ Host information
        hostInfo = name: let
          host = nixosConfigurations.''${name};
          allUsers = builtins.attrNames host.config.users.users;
          defaultUser = user:
            (lib.hasPrefix "nixbld" user)
            || (builtins.elem user [
              "root"
              "nobody"
              "messagebus"
              "systemd-coredump"
              "systemd-network"
              "systemd-oom"
              "systemd-resolve"
              "systemd-timesync"
              "polkituser"
              "rtkit"
              "geoclue"
              "nscd"
              "sddm"
              "dhcpcd"
              "fwupd-refresh"
              "nm-iodine"
              "nm-openvpn"
            ]);
        in {
          hostname = host.config.networking.hostName;
          system = host.config.nixpkgs.hostPlatform.system;
          stateVersion = host.config.system.stateVersion;
          kernel = host.config.boot.kernelPackages.kernel.version;
          users = {
            custom = builtins.filter (u: !defaultUser u) allUsers;
            system = builtins.filter defaultUser allUsers;
          };
          desktop = with host.config.services.desktopManager;
            if plasma6.enable or false
            then "plasma"
            else if gnome.enable or false
            then "gnome"
            else if cosmic.enable or false
            then "cosmic"
            else null;
        };

        #~@ Host comparison
        compareHosts = host1: host2: let
          h1 = nixosConfigurations.''${host1};
          h2 = nixosConfigurations.''${host2};
        in {
          systems = {
            "''${host1}" = h1.config.nixpkgs.hostPlatform.system;
            "''${host2}" = h2.config.nixpkgs.hostPlatform.system;
          };
          kernels = {
            "''${host1}" = h1.config.boot.kernelPackages.kernel.version;
            "''${host2}" = h2.config.boot.kernelPackages.kernel.version;
          };
          stateVersions = {
            "''${host1}" = h1.config.system.stateVersion;
            "''${host2}" = h2.config.system.stateVersion;
          };
        };

        #~@ Service queries
        hostsWithService = service:
          builtins.attrNames (lib.filterAttrs
            (name: host: lib.attrByPath (lib.splitString "." service) false host.config)
            nixosConfigurations);

        enabledServices = hostName: let
          host = nixosConfigurations.''${hostName};
          services = host.config.systemd.services;
        in
          builtins.attrNames (lib.filterAttrs (n: v: v.enable or false) services);
      };

      # Get the current host (to flatten at top level)
      currentHost =
        if matchingHost != null
        then matchingHost
        else lib.head (lib.attrValues nixosConfigurations);
    in {
      config = currentHost.config;
      options = currentHost.options;
      pkgs = if matchingHost != null then matchingHost.pkgs else pkgs;
      inherit lib helpers;

      #~@ Convenient shortcuts to config sections
      inherit (currentHost.config)
        boot
        environment
        hardware
        home-manager
        networking
        programs
        services
        systemd
        users
        ;
    }
  '';

  # Create REPL module file
  replModuleFile = pkgs.writeText "repl-module.nix" replModuleContent;
in
  pkgs.mkShell {
    name = "nixos-config-repl";

    packages = with pkgs; [
      jq
      nixpkgs-fmt
      nil
      nixd
      alejandra
    ];

    shellHook = ''
      # Export environment variables
      export __REPL_MODULE="${replModuleFile}"
      export CURRENT_HOST="${currentHost.config.networking.hostName}"
      export CURRENT_SYSTEM="${system}"

      # Create wrapper scripts
      mkdir -p .direnv/bin

      # nixos-repl: loads the generated module
      cat > .direnv/bin/nixos-repl << 'EOF'
      #!/usr/bin/env bash
      exec nix repl --impure "${replModuleFile}" "$@"
      EOF

      # repl: loads the original repl.nix file
      cat > .direnv/bin/repl << 'EOF'
      #!/usr/bin/env bash
      exec nix repl --impure "${toString ./repl.nix}" "$@"
      EOF

      # Simple helper scripts using nix eval directly with the flake
      cat > .direnv/bin/h-hosts << 'EOF'
      #!/usr/bin/env bash
      nix eval --impure --expr 'builtins.attrNames (builtins.getFlake (toString ./.)).nixosConfigurations' --json | jq -r '.[]'
      EOF

      cat > .direnv/bin/h-info << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      nix eval --impure --expr '
        let
          flake = builtins.getFlake (toString ./.);
          host = flake.nixosConfigurations."'"$host"'";
        in {
          hostname = host.config.networking.hostName;
          system = host.config.nixpkgs.hostPlatform.system;
          kernel = host.config.boot.kernelPackages.kernel.version;
          stateVersion = host.config.system.stateVersion;
        }
      ' --json | jq .
      EOF

      # Make scripts executable
      chmod +x .direnv/bin/*
      export PATH="$PWD/.direnv/bin:$PATH"

      # Create shell functions
      h-list() {
        printf "\033[1;36m#~@ Available helpers\033[0m\n"
        printf "  \033[1;32mh-hosts\033[0m             - List all hosts\n"
        printf "  \033[1;32mh-info [host]\033[0m       - Show host info\n"
        printf "  \033[1;32mnixos-repl\033[0m          - Start Nix REPL with full module\n"
        printf "  \033[1;32mrepl\033[0m                - Start Nix REPL with original file\n"
        printf "\n"
        printf "\033[1;36m#~@ Quick scripts\033[0m\n"
        printf "  \033[1;33mh-rebuild [host]\033[0m    - sudo nixos-rebuild switch --flake .#[host]\n"
        printf "  \033[1;33mh-test [host]\033[0m       - sudo nixos-rebuild test --flake .#[host]\n"
        printf "  \033[1;33mh-boot [host]\033[0m       - sudo nixos-rebuild boot --flake .#[host]\n"
        printf "  \033[1;33mh-dry [host]\033[0m        - sudo nixos-rebuild dry-build --flake .#[host]\n"
        printf "  \033[1;33mh-update\033[0m            - nix flake update\n"
        printf "  \033[1;33mh-clean\033[0m             - sudo nix-collect-garbage -d\n"
      }

      h-rebuild() {
        local host="''\${1:-${currentHost.config.networking.hostName}}"
        printf "sudo nixos-rebuild switch --flake .#%s\n" "$host"
      }

      h-test() {
        local host="''\${1:-${currentHost.config.networking.hostName}}"
        printf "sudo nixos-rebuild test --flake .#%s\n" "$host"
      }

      h-boot() {
        local host="''\${1:-${currentHost.config.networking.hostName}}"
        printf "sudo nixos-rebuild boot --flake .#%s\n" "$host"
      }

      h-dry() {
        local host="''\${1:-${currentHost.config.networking.hostName}}"
        printf "sudo nixos-rebuild dry-build --flake .#%s\n" "$host"
      }

      h-update() {
        printf "nix flake update\n"
      }

      h-clean() {
        printf "sudo nix-collect-garbage -d\n"
      }

      repl-help() {
        printf "\033[1;36m#> NixOS Configuration REPL\033[0m\n"
        printf "\033[1;36m#> Current context:\033[0m\n"
        printf "  Host: \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
        printf "  System: \033[1;32m${system}\033[0m\n"
        printf "\n"
        printf "\033[1;36m#> Available in nix repl:\033[0m\n"
        printf "  config.*           - Current host configuration\n"
        printf "  helpers.*          - Helper functions\n"
        printf "  pkgs               - Current host packages\n"
        printf "  boot.*             - Boot configuration\n"
        printf "  networking.*       - Network configuration\n"
        printf "  services.*         - Services configuration\n"
        printf "\n"
        printf "\033[1;36m#> Quick commands:\033[0m\n"
        printf "  h-list             - Show this help\n"
        printf "  h-hosts            - List all hosts\n"
        printf "  h-info [host]      - Show host information\n"
        printf "  nixos-repl         - Start Nix REPL\n"
      }

      # Show welcome message
      printf "\033[1;36m🎯 NixOS Configuration REPL\033[0m\n"
      printf "\033[1;30m============================\033[0m\n\n"
      printf "\033[1;33mCurrent host:\033[0m \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
      printf "\033[1;33mSystem:\033[0m \033[1;32m${system}\033[0m\n\n"
      printf "Type 'h-list' for available helpers\n"
      printf "Type 'nixos-repl' to start Nix REPL\n\n"
    '';
  }
