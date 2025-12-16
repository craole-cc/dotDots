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

  #> Get the current host (to flatten at top level)
  currentHost =
    if matchingHost != null
    then matchingHost
    else lib.attrsets.head (lib.attrsets.attrValues nixosConfigurations);

  #> Flatten current host's attributes
  currentHostFlattened = {
    # Top-level host attributes
    inherit
      (currentHost)
      _module
      _type
      class
      config
      extendModules
      options
      pkgs
      type
      ;

    # Convenient shortcuts to config sections
    inherit
      (currentHost.config)
      boot
      environment
      hardware
      networking
      programs
      services
      systemd
      users
      ;

    # Add a few more useful ones
    cfg = currentHost.config;
    opts = currentHost.options;
  };
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
  // nixosConfigurations # All hosts still available by name
  // currentHostFlattened
# Current host's attrs at top level
