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
  #> Helper functions for the repl
  helpers = {
    # Generate rebuild commands (copy-paste ready)
    rebuild = host: "sudo nixos-rebuild switch --flake .#${host}";
    test = host: "sudo nixos-rebuild test --flake .#${host}";
    boot = host: "sudo nixos-rebuild boot --flake .#${host}";

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
      kernel = host.config.boot.kernelPackages.kernel.version;
      users = lib.attrNames host.config.users.users;
      desktops = lib.filter (x: x != null) [
        (host.config.services.desktopManager.plasma6.enable or false)
        (host.config.services.desktopManager.gnome.enable or false)
        (host.config.services.desktopManager.cosmic.enable or false)
      ];
    };

    # Compare two hosts
    compareHosts = host1: host2: let
      h1 = nixosConfigurations.${host1};
      h2 = nixosConfigurations.${host2};
    in {
      systems = {
        "${host1}" = h1.config.nixpkgs.hostPlatform.system;
        "${host2}" = h2.config.nixpkgs.hostPlatform.system;
      };
      kernels = {
        "${host1}" = h1.config.boot.kernelPackages.kernel.version;
        "${host2}" = h2.config.boot.kernelPackages.kernel.version;
      };
      stateVersions = {
        "${host1}" = h1.config.system.stateVersion;
        "${host2}" = h2.config.system.stateVersion;
      };
    };

    # Find which hosts have a specific service enabled
    hostsWithService = service:
      lib.attrNames (lib.filterAttrs
        (name: host: lib.attrByPath (lib.splitString "." service) false host.config)
        nixosConfigurations);

    # List all enabled services for a host
    enabledServices = hostName: let
      host = nixosConfigurations.${hostName};
      services = host.config.systemd.services;
    in
      lib.attrNames (lib.filterAttrs (n: v: v.enable or false) services);
  };

  #> Get the current host (to flatten at top level)
  currentHost =
    if matchingHost != null
    then matchingHost
    else lib.attrsets.head (lib.attrsets.attrValues nixosConfigurations);

  #> Flatten current host's attributes
  currentHostFlattened = {
    #~@ Top-level host attributes
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

    #~@ Convenient shortcuts to config sections
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
