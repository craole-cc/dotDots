{
  description = "NixOS Configuration Flake";
  inputs = {
    nixed.url = "github:Craole/nixed";
    nixosStable.url = "nixpkgs/nixos-24.05";
    nixosUnstable.url = "nixpkgs/nixos-unstable";
    nixosHardware.url = "github:NixOS/nixos-hardware";
    nixDarwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    homeManager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        home-manager.follows = "homeManager";
      };
    };
    stylix.url = "github:danth/stylix";
  };
  outputs =
    { self, ... }@inputs:
    let
      lib = with inputs; nixosUnstable.lib // nixDarwin.lib // homeManager.lib;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.attrsets) mapAttrs;
      inherit (lib.lists)
        foldl'
        filter
        length
        head
        ;
      mkConfig =
        name: extraArgs:
        let
          paths =
            let
              flake = {
                local = "/home/craole/Documents/dotfiles";
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
                default = modules.store + "/core";
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

          #@ Define the host config
          host =
            import (paths.core.configurations.hosts + "/${name}")
            // {
              inherit name;
              #| Universial Configuration Overrides
              location = {
                latitude = 18.015;
                longitude = 77.49;
                timeZone = "America/Jamaica";
                defaultLocale = "en_US.UTF-8";
              };
            }
            // extraArgs;

          #@ Filter enabled users based on the 'enable' and 'autoLogin' attributes
          enabledUsers = map (user: user.name) (filter (user: user.enable or true) host.people);
          autologinUsers = filter (user: user.autoLogin or false) host.people;
          autologinUser = if length autologinUsers <= 1 then (head autologinUsers).name else null;

          #@ Import user configurations for enabled users
          users = foldl' (
            acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
          ) { } enabledUsers;

          specialModules =
            let
              core =
                (with paths.core; [
                  libraries
                  modules
                  options
                ])
                ++ (with inputs; [
                  stylix.nixosModules.stylix
                ]);
              home =
                let
                  inherit (host) desktop;
                in
                (with paths.home; [

                ])
                ++ (
                  with inputs;
                  if desktop == "hyprland" then
                    [ ]
                  else if desktop == "plasma" then
                    [
                      plasmaManager.homeManagerModules.plasma-manager
                    ]
                  else if desktop == "xfce" then
                    [ ]
                  else
                    [ ]
                );
            in
            {
              inherit core home;
            };

          specialArgs =
            #TODO add assertion for required args from host, like system

            #@ Check for autoLogin constraints
            assert
              length autologinUsers <= 1
              || throw "Error: Multiple users designated for autologin (${
                concatStringsSep ", " (map (user: user.name) autologinUsers)
              }). Check the 'host.people' configuration.";
            {
              inherit
                paths
                users
                ;
              host = host // {
                inherit autologinUser;
              };
              flake = self;
              modules = specialModules;
              # lib = import (paths.core + "/libraries");
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

      darwinConfigurations = {
        MBPoNine = mkConfig "MBPoNine" { };
      };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = {
      #   craole = mkHome {
      #     name = "craole";
      #   };
      # };
    };
}
