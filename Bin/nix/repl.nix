{
  inputs,
  lib,
  lix,
  api,
  all,
}: let
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
    filter
    findFirst
    splitString
    ;

  #> Get pkgs based on the system running nix repl
  system = builtins.currentSystem;

  #> Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (attrValues nixosConfigurations);

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
    in {
      hostname = host.config.networking.hostName;
      system = host.config.nixpkgs.hostPlatform.system;
      stateVersion = host.config.system.stateVersion;
      kernel = host.config.boot.kernelPackages.kernel.version;
      users = attrNames host.config.users.users;
      desktops = filter (x: x != null) (
        with host.config.services.desktopManager; [
          (plasma6.enable or false && "plasma6")
          (gnome.enable or false && "gnome")
          (cosmic.enable or false && "cosmic")
        ]
      );
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

  #> Flatten current host's attributes
  currentHostFlattened = {
    #~@ Top-level host attributes
    inherit
      (currentHost)
      # _module
      # _type
      # class
      config
      # extendModules
      options
      pkgs
      # type
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
      api
      lib
      pkgs
      builtins
      system
      helpers
      all
      ;
  }
  // currentHostFlattened
