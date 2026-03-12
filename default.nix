{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> {inherit system;},
  self ? null,
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
    mapAttrsRecursive
    ;
  inherit (lib.lists) length filter head isList;
  inherit (lib.strings) concatStringsSep splitString;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Internal Imports                                                            |
  #|─────────────────────────────────────────────────────────────────────────────|
  paths = let
    mkPath = {
      root,
      stem,
    }: "${root}/${
      if isList stem
      then concatStringsSep "/" stem
      else stem
    }";

    concatPath = prefix: parts: let
      base = toString prefix;
    in
      if parts == []
      then base
      else "${base}/${concatStringsSep "/" parts}";

    mapStems = prefix:
      mapAttrsRecursive (_: concatPath prefix);

    stems = {
      default = [];
      libs = rec {
        nix = ["Libraries" "nix"];
        shellscript = ["Libraries" "shellscript"];
        rust = ["Libraries" "rust"];
        default = nix;
      };

      api = rec {
        default = ["API" "nix"];
        hosts = default ++ ["hosts"];
        users = default ++ ["users"];
      };

      pkgs = rec {
        default = ["Packages" "nix"];
        global = default ++ ["global"];
        core = default ++ ["core"];
        home = default ++ ["home"];
        overlays = default ++ ["overlays"];
        plugins = default ++ ["plugins"];
      };

      templates = rec {
        default = ["Templates" "nix"];
        rust = default ++ ["rust"];
      };

      images = rec {
        default = ["Assets" "Images"];
        ascii = default ++ ["ascii"];
        logo = default ++ ["logo"];
        wallpaper = default ++ ["wallpaper"];
      };
    };

    roots = {
      store = builtins.path {
        path = ./.;
        name = "dotDots";
      };
      local = ./.;
    };

    resolved = {
      store = mapStems roots.store stems;
      local = mapStems roots.local stems;
    };

    mkPaths = root: {
      inherit root;

      default = mkPath {
        inherit root;
        stem = [];
      };
      libs = let
        nix = mkPath {
          inherit root;
          stem = ["Libraries" "nix"];
        };
        shellscript = mkPath {
          inherit root;
          stem = ["Libraries" "shellscript"];
        };
        rust = mkPath {
          inherit root;
          stem = ["Libraries" "rust"];
        };
      in {
        default = nix;
        inherit nix shellscript rust;
      };
      api = let
        default = mkPath {
          inherit root;
          stem = ["API" "nix"];
        };
        hosts = mkPath {
          root = default;
          stem = "hosts";
        };
        users = mkPath {
          root = default;
          stem = "users";
        };
      in {inherit default hosts users;};
      pkgs = let
        default = mkPath {
          inherit root;
          stem = ["Packages" "nix"];
        };
        core = mkPath {
          root = default;
          stem = "core";
        };
        global = mkPath {
          root = default;
          stem = "global";
        };
        home = mkPath {
          root = default;
          stem = "home";
        };
        overlays = mkPath {
          root = default;
          stem = "overlays";
        };
        plugins = mkPath {
          root = default;
          stem = "plugins";
        };
      in {inherit default core global home overlays plugins;};
      templates = let
        default = mkPath {
          inherit root;
          stem = ["Templates" "nix"];
        };
        rust = mkPath {
          root = default;
          stem = "rust";
        };
      in {inherit default rust;};
      images = rec {
        default = mkPath {
          inherit root;
          stem = ["Assets" "Images"];
        };
        ascii = mkPath {
          root = default;
          stem = "ascii";
        };
        logo = mkPath {
          root = default;
          stem = "logo";
        };
        wallpaper = mkPath {
          root = default;
          stem = "wallpaper";
        };
      };
    };
    store = mkPaths ./.;
    local = mkPaths src;
    mkLocal = dots: mkPaths dots;
  in {inherit roots stems resolved mkPath store local mkLocal;};

  inherit
    (import ./Libraries/nix {inherit lib src;})
    lix
    ; #TODO: Maybe pass in pkgs
  schema = lix.schema.core.all {
    hostsPath = paths.store.api.hosts;
    usersPath = paths.store.api.users;
  };
  inherit (schema) hosts users;
  inherit (lix.modules.predicates) isSystemDefaultUser;
  inherit (lix.modules.resolution) flakeAttrs hostAttrs;
  inherit (lix.inputs.resolution) getInputs;

  #|─────────────────────────────────────────────────────────────────────────────|
  #| Flake & Current Host                                                        |
  #|─────────────────────────────────────────────────────────────────────────────|
  flake = flakeAttrs {inherit self;};
  nixosConfigurations = flake.nixosConfigurations or {};
  host = hostAttrs {inherit nixosConfigurations system;};
  inputs = getInputs {inherit flake host;};

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

      mkConfigSection = corePath: homeAttr: apiAttr: {
        core = attrByPath (splitString "." corePath) {} host.config;
        home =
          if length (attrNames usersData) == 1
          then getHomeAttr homeAttr (head (attrValues usersData))
          else mapAttrs (_name: user: getHomeAttr homeAttr user) usersData;
        api =
          if length (attrNames usersData) == 1
          then getApiAttr apiAttr (head (attrValues usersData))
          else mapAttrs (_name: user: getApiAttr apiAttr user) usersData;
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
    paths
    pkgs
    schema
    system
    ;

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
