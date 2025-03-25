{
  description = "NixOS Configuration Flake";
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = [
          ./darwin/flake-module.nix
          ./machines/flake-module.nix
          ./home-manager/flake-module.nix
          ./terraform/flake-module.nix
          ./devshell/flake-module.nix
          ./pkgs/images/flake-module.nix
          ./pkgs/flake-module.nix
          inputs.hercules-ci-effects.flakeModule
          inputs.clan-core.flakeModules.default
        ];
        systems = [
          "x86_64-linux"
          # "x86_64-darwin"
          # "aarch64-linux"
          # "aarch64-darwin"
        ];

        perSystem =
          {
            inputs',
            self',
            lib,
            system,
            ...
          }:
          {
            _module.args = {
              pkgs = inputs'.nixpkgs.legacyPackages;
            };

            checks =
              let
                machinesPerSystem = {
                  aarch64-linux = [
                    "Raspi"
                  ];
                  x86_64-linux = [
                    "QBX"
                    "dbook"
                    "Preci"
                  ];
                };

                nixosMachines = lib.mapAttrs' (n: lib.nameValuePair "nixos-${n}") (
                  lib.genAttrs (machinesPerSystem.${system} or [ ]) (
                    name: self.nixosConfigurations.${name}.config.system.build.toplevel
                  )
                );

                blacklistPackages = [
                  "install-iso"
                  "nspawn-template"
                  "netboot-pixie-core"
                  "netboot"
                ];

                packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") (
                  lib.filterAttrs (n: _v: !(builtins.elem n blacklistPackages)) self'.packages
                );

                devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;

                homeConfigurations = lib.mapAttrs' (
                  name: config: lib.nameValuePair "home-manager-${name}" config.activation-script
                ) (self'.legacyPackages.homeConfigurations or { });
              in
              nixosMachines // packages // devShells // homeConfigurations;
          };
      }
    );

  inputs = {
    #| Core
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixStable.url = "nixpkgs/nixos-24.11";
    nixUnstable.url = "nixpkgs/nixos-unstable";
    # nixPackages= "nixpkgs/nixos-unstable";
    nixSystems = {
      type = "github";
      owner = "nix-systems";
      repo = "default";
    };
    nixHardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
    };
    nixCache = {
      type = "github";
      owner = "nix-community";
      repo = "harmonia";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixDarwin = {
      type = "github";
      owner = "lnl7";
      repo = "nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixWSL = {
      type = "github";
      owner = "nix-community";
      repo = "NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixIndex = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixUnit = {
      type = "github";
      owner = "nix-community";
      repo = "nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #| Utilities
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    #| Templates
    nixed = {
      # url = "github:Craole/nixed";
      type = "github";
      owner = "Craole";
      repo = "nixed";
    };

    # haumea = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "haumea";
    # };

    # easy-hosts = {
    #   type = "github";
    #   owner = "tgirlcloud";
    #   repo = "easy-hosts";
    # };

    # deploy-rs = {
    #   type = "github";
    #   owner = "serokell";
    #   repo = "deploy-rs";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #   };
    # };

    devshell = {
      type = "github";
      owner = "numtide";
      repo = "devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # git-hooks = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "git-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # nix-github-actions = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "nix-github-actions";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    treefmt-nix = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-hardware = {
    #   type = "github";
    #   owner = "NixOS";
    #   repo = "nixos-hardware";
    # };

    # disko = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # impermanence = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "impermanence";
    # };

    # hyprland = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "git-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    #| Core
    # nixpkgs = {
    #   url = "nixpkgs/nixos-unstable";
    # };
    # homeManager = {
    #   url = "github:nix-community/home-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #   };
    # };

    #| Utilities
    # flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-unified.url = "github:srid/nixos-unified";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # agenix.url = "github:ryantm/agenix";
    # nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #| Software inputs
    # github-nix-ci.url = "github:juspay/github-nix-ci";
    # nixos-vscode-server = {
    #   url = "github:nix-community/nixos-vscode-server";
    #   flake = false;
    # };
    # omnix.url = "github:juspay/omnix";
    # hyprland.url = "github:hyprwm/Hyprland/v0.46.2";
    # plasmaManager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";

    #| Neovim
    # nixvim = {
    #   url = "github:nix-community/nixvim";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Devshell
    # git-hooks = {
    #   url = "github:cachix/git-hooks.nix";
    #   flake = false;
    # };
  };
}
