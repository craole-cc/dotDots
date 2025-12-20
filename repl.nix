let
  src = ./.;
  inherit (import (src + "/Libraries") {inherit src;}) lix;
  api = import (src + "/API") {inherit lix;};
  inherit (api) hosts;
  inherit (lix) lib;

  lic = lix.configuration.resolution;
  inherit (lix.configuration.predicates) isSystemDefaultUser;

  flake = lic.flake {path = src;};
  nixosConfigurations = flake.nixosConfigurations or {};

  systems = lic.systems {inherit hosts;};
  inherit (systems) pkgs system;

  host = lic.host {inherit nixosConfigurations system;};

  inherit (lib.attrsets) attrByPath attrNames filterAttrs;
  inherit (lib.lists) filter;
  inherit (lib.strings) splitString;

  #> Helper functions for the repl
  helpers = {
    #~@ Script generators (copy-paste ready)
    scripts = {
      rebuild = host: "sudo nixos-rebuild switch --flake .#${host}";
      test = host: "sudo nixos-rebuild test --flake .#${host}";
      boot = host: "sudo nixos-rebuild boot --flake .#${host}";
      dry = host: "sudo nixos-rebuild dry-build --flake .#${host}";
      update = "nix flake update";
      clean = "sudo nix-collect-garbage -d";
    };

    #~@ Host discovery
    listHosts = attrNames nixosConfigurations;
    getHost = name: nixosConfigurations.${name} or null;

    #~@ Host information
    hostInfo = name: let
      host = nixosConfigurations.${name};
      cfg = host.config;
      allUsers = attrNames cfg.users.users;
    in {
      inherit (cfg.networking) hostName;
      inherit (cfg.nixpkgs.hostPlatform) system;

      version = {
        kernel = cfg.boot.kernelPackages.kernel.version;
        initial = cfg.system.stateVersion;
        nixos = cfg.system.nixos.version;
      };

      users = {
        # TODO: Here we should show username and type isNormalUser vs isSystemUser
        custom = filter (u: !isSystemDefaultUser u) allUsers;
        system = filter isSystemDefaultUser allUsers;
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

    #~@ Service queries
    hostsWithService = service:
      attrNames (filterAttrs
        (name: host: attrByPath (splitString "." service) false host.config)
        nixosConfigurations);

    enabledServices = hostName: let
      host = nixosConfigurations.${hostName};
      services = host.config.systemd.services;
    in
      attrNames (filterAttrs (n: v: v.enable or false) services);
  };
in
  {
    inherit
      lix
      api
      lib
      builtins
      # system
      helpers
      flake
      ;
    # pkgs = matchingHost.pkgs or pkgs;
  }
  // {
    #~@ Top-level host attributes
    inherit
      (host)
      config
      options
      # pkgs
      ;

    inherit (host._module) specialArgs;
    inherit (flake) inputs;

    #~@ Convenient shortcuts to config sections
    inherit
      (host.config)
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

    inherit pkgs system systems;
  }
