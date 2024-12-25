{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosStable.url = "nixpkgs/nixos-24.05";
    nixosHardware.url = "github:NixOS/nixos-hardware";
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nid = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed.url = "github:Craole/nixed";
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "homeManager";
      };
    };
    stylix.url = "github:danth/stylix";
  };
  outputs =
    { self, ... }@inputs:
    let
      mkConfig =
        name: extraArgs:
        let
          paths =
            let
              flake = {
                local = "/home/craole/Documents/dotfiles";
                root = "/dots";
                link = "~/.dots";
                store = ./.;
              };
              parts = {
                args = "/args";
                cfgs = "/configurations";
                env = "/environment";
                libs = "/libraries";
                mkCore = "/helpers/makeCoreConfig.nix";
                modules = "/Configuration/apps/nixos";
                mods = "/modules";
                opts = "/options";
                pkgs = "/packages";
                scripts = "/Bin";
                svcs = "/services";
                ui = "/ui";
                uiCore = "/ui/core";
                uiHome = "/ui/home";
                hosts = parts.cfgs + "/hosts";
                users = parts.cfgs + "/users";
              };
              core = {
                default = modules.store;
                configurations = {
                  hosts = core.default + parts.hosts;
                  users = core.default + parts.users;
                };
                environment = core.default + parts.env;
                libraries = core.default + parts.libs;
                modules = core.default + parts.mods;
                options = core.default + parts.opts;
                packages = core.default + parts.pkgs;
                services = core.default + parts.svcs;
              };
              home = {
                default = modules.store + "/home";
                configurations = home.default + parts.cfgs;
                environment = home.default + parts.env;
                libraries = home.default + parts.libs;
                modules = home.default + parts.mods;
                options = home.default + parts.opts;
                packages = home.default + parts.pkgs;
                services = home.default + parts.svcs;
              };
              scripts = {
                local = flake.local + parts.scripts;
                store = flake.store + parts.scripts;
              };
              modules = {
                local = flake.local + parts.modules;
                store = flake.store + parts.modules;
              };
              libraries = {
                local = modules.local + parts.libs;
                store = modules.store + parts.libs;
                mkCore = core.libraries + parts.mkCore;
              };
            in
            {
              inherit
                flake
                core
                home
                scripts
                parts
                modules
                libraries
                ;
            };
          host =
            let
              inherit (inputs.nixpkgs.lib.lists) foldl' filter;
              confCommon = import (paths.core.configurations.hosts + "/common");
              confSystem = import (paths.core.configurations.hosts + "/${name}");
              enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
              userConfigs = foldl' (
                acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
              ) { } enabledUsers;
            in
            {
              inherit name userConfigs;
            }
            // confCommon
            // confSystem
            // extraArgs;
          specialModules =
            let
              inherit (host) desktop;
              core =
                (with paths.core; [
                  libraries
                  modules
                  options
                ])
                ++ (with inputs; [
                  stylix.nixosModules.stylix
                  nid.nixosModules.nix-index
                ]);
              home =
                with inputs;
                if desktop == "hyprland" then
                  [ ]
                else if desktop == "plasma" then
                  [ plasmaManager.homeManagerModules.plasma-manager ]
                else if desktop == "xfce" then
                  [ ]
                else
                  [ ];
            in
            {
              inherit core home;
            };

          specialArgs = {
            inherit self paths host;
            modules = specialModules;
            libraries = import paths.libraries.store; # TODO: Check on this
          };
        in
        import paths.libraries.mkCore {
          inherit (inputs)
            nixosStable
            nixosUnstable
            homeManager
            nixDarwin
            ;

          inherit (host)
            name
            system
            ;

          inherit
            specialArgs
            specialModules
            ;

          preferredRepo = host.preferredRepo or "unstable";
          allowUnfree = host.allowUnfree or true;
          allowAliases = host.allowAliases or true;
          allowHomeManager = host.allowHomeManager or true;
          backupFileExtension = host.backupFileExtension or "BaC";
          extraPkgConfig = host.extraPkgConfig or { };
          extraPkgAttrs = host.extraPkgAttrs or { };
        };
    in
    {
      nixosConfigurations = {
        preci = mkConfig "preci" { };
        dbook = mkConfig "dbook" { };
      };

      #TODO: Create seperate config directory for nix systems since the config is drastically different
      # darwinConfigurations = {
      #   MBPoNine = mkConfig "MBPoNine" { };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = mkConfig "craole" { };
    };
}
