let
  src = ../../../.;
  inherit (import (src + "/Libraries") {inherit src;}) lix;
  # inherit (lix.configuration.resolution) flakeWithSrcPath;
  api = import (src + "/API") {inherit lix;};
  all = lix.flakeWithSrcPath src src;

  inherit (all) inputs;
  lib = inputs.nixpkgs.lib;
  system = builtins.currentSystem or "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  nixosConfigurations = all.nixosConfigurations or {};

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

  #> Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (attrValues nixosConfigurations);

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

    #~@ Current context
    currentHostName = currentHost.config.networking.hostName;

    #~@ Host information
    hostInfo = name: let
      host = nixosConfigurations.${name};
      allUsers = attrNames host.config.users.users;
      defaultUser = user:
        (lib.hasPrefix "nixbld" user)
        || (elem user [
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
        # TODO: Here we should show username and type isNormalUser vs isSystemUser
        custom = filter (u: !defaultUser u) allUsers;
        system = filter defaultUser allUsers;
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

  #> Get the current host (to flatten at top level)
  currentHost =
    if matchingHost != null
    then matchingHost
    else head (attrValues nixosConfigurations);
in
  {
    inherit
      lix
      api
      lib
      builtins
      system
      helpers
      all
      ;
    pkgs = matchingHost.pkgs or pkgs;
  }
  // {
    #~@ Top-level host attributes
    inherit
      (currentHost)
      config
      options
      pkgs
      ;

    inherit (currentHost._module) specialArgs;
    inherit (all) inputs;

    #~@ Convenient shortcuts to config sections
    inherit
      (currentHost.config)
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
