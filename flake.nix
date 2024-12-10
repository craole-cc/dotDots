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
      alpha = "craole";
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
          ui ? {
            env = "hyprland";
          },
        }:
        let
          paths =
            let
              flake = {
                local = "/home/craole/Documents/dotfiles";
                store = ./.;
              };
              parts = {
                modules = "/Configuration/apps/nixos";
                scripts = "/Bin";
                conf = "/configurations";
                mkCore = "/helpers/makeCoreConfig.nix";
                uiCore = "/ui/core";
                uiHome = "/ui/home";
                env = "/environment";
                lib = "/libraries";
                ui = "/ui";
                args = "/args";
              };
              core = {
                default = modules.store + "/core";
                env = core.default + parts.env;
                lib = core.default + parts.lib;
                ui = core.default + parts.ui;
                conf = core.default + parts.conf;
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
                local = modules.local + parts.libraries;
                store = modules.store + parts.libraries;
                mkCore = core.lib + parts.mkCore;
              };
            in
            {
              inherit
                flake
                core
                scripts
                parts
                modules
                libraries
                ;
            };
          specialModules =
            let
              core =
                [ paths.core.default ]
                ++ (with inputs; [
                  stylix.nixosModules.stylix
                ]);
              home =
                (with paths; [
                  # (modules.store + parts.uiHome + "/${ui.env}")
                ])
                ++ (
                  with inputs;
                  if ui.env == "hyprland" then
                    [ ]
                  else if ui.env == "plasma" then
                    [
                      plasmaManager.homeManagerModules.plasma-manager
                    ]
                  else if ui.env == "xfce" then
                    [ ]
                  else
                    [ ]
                );
            in
            { inherit core home; } // extraMods;
          specialArgs = {
            inherit
              paths
              alpha
              ui
              ;
            flake = self;
            modules = specialModules;
            # lib = import (paths.core + "/libraries");
            host = import (paths.core.conf + "/${name}" + "/data") // {
              inherit name system;
              location = {
                latitude = 18.015;
                longitude = 77.49;
                timeZone = "America/Jamaica";
                defaultLocale = "en_US.UTF-8";
              };
            };
          } // extraArgs;
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
          ui.env = "plasma";
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
