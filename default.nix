{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> {inherit system;},
  self ? {},
  src ? ./.,
  system ? builtins.currentSystem,
  ...
}: let
  #|─────────────────────────────────────────────────────────────────────────────|
  #| External Imports                                                            |
  #|─────────────────────────────────────────────────────────────────────────────|
  inherit
    (lib.attrsets)
    attrByPath
    attrNames
    attrValues
    filterAttrs
    listToAttrs
    mapAttrs
    ;
  inherit (lib.lists) length filter head;
  inherit (lib.strings) splitString;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Internal Imports                                                            |
  #|─────────────────────────────────────────────────────────────────────────────|
  inherit (import ./Libraries/nix {inherit lib src;}) lix;
  flake = lix.mkFlake {};
  tree = lix.mkProjectTree {inherit flake;};
  schema = lix.mkSchema {inherit tree;};
  inputs = lix.mkInputs {inherit self;};

  inherit (schema) hosts users;
  inherit (lix.modules.core.predicates) isSystemDefaultUser;

  nixosConfigurations = flake.nixosConfigurations or {};
  # host = hostAttrs {inherit nixosConfigurations system;};
  host = {};

  #|─────────────────────────────────────────────────────────────────────────────|
  #| REPL Helpers                                                                |
  #|─────────────────────────────────────────────────────────────────────────────|
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

      version = {
        kernel = cfg.boot.kernelPackages.kernel.version;
        state = cfg.system.stateVersion;
        nixos = cfg.system.nixos.version;
      };

      userList = {
        custom = filter (u: !isSystemDefaultUser u) allUsers;
        system = filter isSystemDefaultUser allUsers;
      };

      usersData = listToAttrs (map (user: {
          name = user;
          value = {
            core = cfg.users.users.${user};
            home = let hm = cfg.home-manager.users.${user}; in hm // hm.home;
            api = users.${user};
          };
        })
        userList.custom);

      getHomeAttr = attr: user: user.home.${attr} or {};
      getApiAttr = attr: user: user.api.${attr} or {};

      mkConfigSection = {
        path,
        homeAttr,
        apiAttr,
      }: {
        core = attrByPath (splitString "." path) {} (host.config or{});
        home =
          if length (attrNames usersData) == 1
          then
            getHomeAttr {
              attr = homeAttr;
              user = head (attrValues usersData);
            }
          else
            mapAttrs (_: user:
              getHomeAttr {
                attr = homeAttr;
                inherit user;
              })
            usersData;
        api =
          if length (attrNames usersData) == 1
          then
            getApiAttr {
              attr = apiAttr;
              name = head (attrValues usersData);
            }
          else
            mapAttrs (_: user:
              getApiAttr {
                attr = apiAttr;
                inherit user;
              })
            usersData;
      };

      programs = mkConfigSection "programs" "programs" "programs";
      services = mkConfigSection "services" "services" "services";
      variables = mkConfigSection "environment.sessionVariables" "sessionVariables" "variables";
      aliases = mkConfigSection "environment.shellAliases" "shellAliases" "aliases";
      packages = mkConfigSection "environment.systemPackages" "packages" "packages";

      desktopEnvironment = with cfg.services.desktopManager;
        if plasma6.enable or false
        then "plasma"
        else if gnome.enable or false
        then "gnome"
        else if cosmic.enable or false
        then "cosmic"
        else null;
    in {
      inherit
        version
        usersData
        userList
        desktopEnvironment
        programs
        services
        variables
        aliases
        packages
        ;
      users = usersData;
      inherit (cfg.networking) hostName;
      inherit (cfg.nixpkgs.hostPlatform) system;
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
        (_name: host: attrByPath (splitString "." service) false host.config)
        nixosConfigurations);

    enabledServices = hostName: let
      host = nixosConfigurations.${hostName};
      services = host.config.systemd.services;
    in
      attrNames (filterAttrs (_n: v: v.enable or false) services);
  };
in {
  inherit
    flake
    helpers
    hosts
    inputs
    lib
    lix
    pkgs
    schema
    system
    tree
    ;
  paths = tree;

  #~@ Top-level host attributes
  inherit (host) config options;
  inherit (host._module) specialArgs;

  #~@ Convenient shortcuts to config sections
  inherit
    (helpers.hostInfo host.name)
    users
    aliases
    packages
    programs
    services
    variables
    ;
}
