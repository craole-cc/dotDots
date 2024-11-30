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
  };
  outputs =
    inputs@{
      self,
      nixosStable,
      nixosUnstable,
      homeManager,
      nixDarwin,
      ...
    }:
    let
      inherit (inputs.nixosUnstable) lib;
      inherit (lib.modules) mkForce;
      inherit (builtins) getEnv baseNameOf;
      paths =
        let
          flake = {
            local = "/home/craole/Documents/dotfiles";
            store = ./.;
          };
          names = {
            modules = "/Configuration/apps/nixos";
            scripts = "/Bin";
            libraries = "/libraries";
            hosts = "/hosts/configurations";
            mkCore = "/helpers/makeCoreConfig.nix";
          };
          scripts = {
            local = flake.local + names.scripts;
            store = flake.store + names.scripts;
          };
          modules = {
            local = flake.local + names.modules;
            store = flake.store + names.modules;
          };
          libraries = {
            local = modules.local + names.libraries;
            store = modules.store + names.libraries;
          };
        in
        {
          inherit
            flake
            names
            scripts
            modules
            libraries
            ;
        };
      init =
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
        }:
        import (with paths; libraries.store + names.mkCore) {
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
            inputs
            ;
          inherit (inputs)
            nixosStable
            nixosUnstable
            homeManager
            nixDarwin
            ;
          corePath = paths.modules.store;
          coreMods = {
            environment = {
              variables = with paths; {
                DOTS = flake.local;
                DOTS_RC = flake.local + "/.dotsrc";
                DOTS_BIN = scripts.local;
                DOTS_NIX = modules.local;
                NIXOS_CONFIG = with paths; modules.local + names.hosts + "/${name}";
                NIXOS_FLAKE = flake.local;
              };
              shellAliases = {
                Flake = ''pushd ${paths.flake.local} && { { { command -v geet && geet ;} || git add --all; git commit --message "Flake Update" ;} ; sudo nixos-rebuild switch --flake . --show-trace ;}; popd'';
                Flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
                Flash = ''geet --path ${paths.flake.local} && sudo nixos-rebuild switch --flake ${paths.flake.local} --show-trace'';
                Flick = ''Flush && Flash && Reboot'';
                Reboot = ''leave --reboot'';
                Reload = ''leave --logout'';
                Retire = ''leave --shutdown'';
                Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
                q = ''leave --terminal'';
                ".." = "cd .. || return 1";
                "..." = "cd ../.. || return 1";
                "...." = "cd ../../.. || return 1";
                "....." = "cd ../../../.. || return 1";
                h = "history";
              };
              extraInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
            };
          };
          # extraMods = {
          #   core = [ ];
          # };
          homeMods = with inputs; [
            plasmaManager.homeManagerModules.plasma-manager
          ];
          specialArgs = {
            inherit paths;
            flake = self;
          } // extraArgs;
        };
    in
    {
      nixosConfigurations = {
        preci = init {
          name = "preci";
          system = "x86_64-linux";
        };
        dbook = init {
          name = "dbook";
          system = "x86_64-linux";
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
