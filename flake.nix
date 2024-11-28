{
  description = "NixOS Configuration Flake";
  inputs = {
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
    nixed.url = "github:Craole/nixed";
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
              variables =
                let
                  hostPath = with paths; modules.local + names.hosts + "/${name}";
                  nixPath = rec {
                    def = "$HOME/.nix-defexpr/channels";
                    etc = "/etc/nixos/configuration.nix";
                    channels = "/nix/var/nix/profiles/per-user/root/channels";
                    # pkgs = channels + "/nixos";
                    pkgs = "flake";
                    host = with paths; modules.local + names.hosts + "/${name}";
                    env = "${def}:nixpkgs=${pkgs}:nixos-config=${etc}:${channels}:${host}";
                  };
                in
                # nixPath = "${getEnv "NIX_PATH"}:nixos-config=/etc/nixos${hostPath}";
                with paths;
                {
                  DOTS = flake.local;
                  DOTS_BIN = scripts.local;
                  DOTS_MODS_NIX = modules.local;
                  DOTS_NIX = hostPath;
                  NIX_PATH = mkForce nixPath.env;
                  test_nix_path_def = nixPath.def;
                  test_nix_path_etc = nixPath.etc;
                  test_nix_path_channels = nixPath.channels;
                  test_nix_path_host = nixPath.host;
                  test_nix_path_env = nixPath.env;

                };
              shellAliases = {
                Flake = ''pushd ${paths.flake.local} && git add --all; git commit --message "Flake Update"; sudo nixos-rebuild switch --flake .; popd'';
              };
              pathsToLink =
                let
                  bin = paths.scripts.local;
                in
                [
                  (bin + "/base")
                  (bin + "/core")
                  (bin + "/import")
                  (bin + "/interface")
                  (bin + "/misc")
                  (bin + "/packages")
                  (bin + "/project")
                  (bin + "/tasks")
                  (bin + "/template")
                  (bin + "/utility")
                ];
            };
          };
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
