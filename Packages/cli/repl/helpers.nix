{
  lib,
  lix,
  api,
  nixosConfigurations,
  isSystemDefaultUser,
  src,
}: let
  inherit (lib.attrsets) attrByPath attrNames attrValues filterAttrs mapAttrs listToAttrs;
  inherit (lib.lists) length filter head;
  inherit (lib.strings) splitString;

  helpers = {
    scripts = {
      rebuild = host: "sudo nixos-rebuild switch --flake .#${host}";
      test = host: "sudo nixos-rebuild test --flake .#${host}";
      boot = host: "sudo nixos-rebuild boot --flake .#${host}";
      dry = host: "sudo nixos-rebuild dry-build --flake .#${host}";
      update = "nix flake update";
      clean = "sudo nix-collect-garbage -d";
    };

    listHosts = attrNames nixosConfigurations;
    getHost = name: nixosConfigurations.${name} or null;

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

      users = listToAttrs (map (user: {
          name = user;
          value = {
            core = cfg.users.users.${user};
            home = let hm = cfg.home-manager.users.${user}; in hm // hm.home;
            api = api.users.${user};
          };
        })
        userList.custom);

      # Helper to safely get attributes with fallback
      getHomeAttr = attr: user: user.home.${attr} or {};
      getApiAttr = attr: user: user.api.${attr} or {};

      # Generic config section maker with three sources
      mkConfigSection = corePath: homeAttr: apiAttr: {
        core = attrByPath (splitString "." corePath) {} host.config;
        home =
          if length (attrNames users) == 1
          then getHomeAttr homeAttr (head (attrValues users))
          else mapAttrs (name: user: getHomeAttr homeAttr user) users;
        api =
          if length (attrNames users) == 1
          then getApiAttr apiAttr (head (attrValues users))
          else mapAttrs (name: user: getApiAttr apiAttr user) users;
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
      inherit version users userList desktopEnvironment programs services variables aliases packages;
      inherit (cfg.networking) hostName;
      inherit (cfg.nixpkgs.hostPlatform) system;
    };

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
in {
  inherit helpers;
}
