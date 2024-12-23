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
      lib = inputs.nixosUnstable.lib;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.lists)
        foldl'
        filter
        length
        head
        ;
      mkConfig =
        {
          name,
          system,
          preferredRepo ? "unstable",
          allowUnfree ? true,
          allowAliases ? true,
          allowHomeManager ? true,
          backupFileExtension ? "BaC",
          enableDots ? false,
          extraPkgConfig ? { },
          extraPkgAttrs ? { },
          extraArgs ? { },
          extraMods ? { },
        }:
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
                users = parts.cfgs + "/hosts";
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
          host = import (paths.core.configurations.hosts + "/${name}") // {
            inherit name system;
            location = {
              latitude = 18.015;
              longitude = 77.49;
              timeZone = "America/Jamaica";
              defaultLocale = "en_US.UTF-8";
            };
          };

          #@ Filter enabled users based on the 'enable' attribute
          enabledUsers = map (user: user.name) (filter (user: user.enable or true) host.people);

          #@ Import user configurations for enabled users
          users = foldl' (
            acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
          ) { } enabledUsers;

          autologinUsers = filter (user: user.autoLogin or false) host.people;
          autologinUser = if length autologinUsers <= 1 then (head autologinUsers).name else null;

          specialModules =
            let
              core =
                (with paths.core; [
                  # default
                  configurations
                  # context
                  environment
                  libraries
                  modules
                  options
                  packages
                  services
                ])
                ++ (with paths.home; [
                  # default
                  # configurations
                  # context
                  # environment
                  # libraries
                  # modules
                  # options
                  # packages
                  # services
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
            { inherit core home; } // extraMods;

          specialArgs =
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
            }
            // extraArgs;
        in
        import paths.libraries.mkCore {
          inherit (inputs)
            nixosStable
            nixosUnstable
            homeManager
            nixDarwin
            ;
          inherit
            name
            system
            preferredRepo
            allowUnfree
            allowAliases
            allowHomeManager
            backupFileExtension
            enableDots
            extraPkgConfig
            extraPkgAttrs
            specialArgs
            specialModules
            ;
        };
    in
    {
      nixosConfigurations = {
        preci = mkConfig {
          name = "preci";
          system = "x86_64-linux";
        };
        dbook = mkConfig {
          name = "dbook";
          system = "x86_64-linux";
          ui.env = "xfce";
        };
      };

      # darwinConfigurations = {
      #   MBPoNine = mkCore {
      #     name = "MBPoNine";
      #     system = "x86_64-darwin";
      #   };
      # };

      # TODO create mkHome for standalone home manager configs
      # homeConfigurations = {
      #   craole = mkHome {
      #     name = "craole";
      #   };
      # };
    };
}
