{
  inputs,
  lib,
  lix,
  nixosConfigurations,
}: let
  #> Get pkgs based on the system running nix repl
  system = builtins.currentSystem;

  #> Find a host that matches current system
  matchingHost =
    lib.lists.findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (lib.attrsets.attrValues nixosConfigurations);

  #> Use matching host's pkgs or create fallback
  pkgs =
    if matchingHost != null
    then matchingHost.pkgs
    else
      import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

  #> Helper functions for the repl
  helpers = {
    # Quick rebuild current host
    rebuild = host: "sudo nixos-rebuild switch --flake .#${host}";

    # List all hosts
    listHosts = lib.attrNames nixosConfigurations;

    # Get host by name
    getHost = name: nixosConfigurations.${name} or null;

    # Pretty print a host's key info
    hostInfo = name: let
      host = nixosConfigurations.${name};
    in {
      hostname = host.config.networking.hostName;
      system = host.config.nixpkgs.hostPlatform.system;
      stateVersion = host.config.system.stateVersion;
      users = lib.attrNames host.config.users.users;
    };
  };

  #> Flatten each host configuration for easier access
  flattenedHosts =
    lib.attrsets.mapAttrs (
      name: host:
        host
        // {
          # Expose common attributes at top level
          inherit (host) config pkgs options _module type;

          # Shortcut to commonly accessed config sections
          cfg = host.config;
          opts = host.options;

          # Expose specific useful config sections
          networking = host.config.networking;
          users = host.config.users;
          environment = host.config.environment;
          services = host.config.services;
          programs = host.config.programs;
          systemd = host.config.systemd;
          boot = host.config.boot;
          hardware = host.config.hardware;
        }
    )
    nixosConfigurations;
in
  {
    inherit
      lix
      lib
      pkgs
      builtins
      system
      helpers
      ;
    hosts = nixosConfigurations;
  }
  // flattenedHosts
