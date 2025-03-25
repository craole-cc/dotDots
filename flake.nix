{
  description = "NixOS Configuration Flake";
  outputs =
    inputs@{ flakeParts, ... }:
    flakeParts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        imports = with inputs; [
          nixosHome.flakeModules.home-manager
          nixosHost.flakeModule
          nixosConfig.flakeModule
          developmentShell.flakeModule
          treeFormatter.flakeModule
          gitPreCommit.flakeModule

          # ./darwin/flake-module.nix
          # ./machines/flake-module.nix
          # ./home-manager/flake-module.nix
          # ./terraform/flake-module.nix
          # ./devshell/flake-module.nix
          # ./pkgs/images/flake-module.nix
          # ./pkgs/flake-module.nix
          # inputs.hercules-ci-effects.flakeModule
          # inputs.clan-core.flakeModules.default
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
    #| NixOS
    # nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs-stable="nixpkgs/nixos-24-11";
    # nixpkgs-unstable="nixpkgs/nixos-unstable";
    nixosStable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-24.11";
    };
    nixosUnstable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
    nixosHardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
    };
    nixosHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    nixosWSL = {
      type = "github";
      owner = "nix-community";
      repo = "NixOS-WSL";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-compat.follows = "flakeCompat";
      };
    };
    nixosDarwin = {
      type = "github";
      owner = "lnl7";
      repo = "nix-darwin";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
#TODO: Add vscode ext
    #| Nix Community Utilities
    nixCache = {
      type = "github";
      owner = "nix-community";
      repo = "harmonia";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-parts.follows = "flakeParts";
        treefmt-nix.follows = "treeFormatter";
      };
    };
    nixDisk = {
      type = "github";
      owner = "nix-community";
      repo = "disko";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    # impermanence = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "impermanence";
    # };
    githubActions = {
      type = "github";
      owner = "nix-community";
      repo = "nix-github-actions";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    nixIndex = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-compat.follows = "flakeCompat";
      };
    };
    nixLib = {
      owner = "nix-community";
      repo = "nixpkgs.lib";
      type = "github";
    };
    nixUnitTesting = {
      type = "github";
      owner = "nix-community";
      repo = "nix-unit";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-parts.follows = "flakeParts";
        treefmt-nix.follows = "treeFormatter";
        nix-github-actions.follows = "githubActions";
      };
    };

    #| Flake Parts (https://flake.parts)
    flakeParts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs = {
        nixpkgs-lib.follows = "nixLib";
      };
    };
    treeFormatter = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
      };
    };
    developmentShell = {
      type = "github";
      owner = "numtide";
      repo = "devshell";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
      };
    };
    gitIgnore = {
      owner = "hercules-ci";
      repo = "gitignore.nix";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
      };
    };
    gitPreCommit = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        gitignore.follows = "gitIgnore";
        flake-compat.follows = "flakeCompat";
      };
    };
    nixosHost = {
      type = "github";
      owner = "tgirlcloud";
      repo = "easy-hosts";
    };
    nixosConfig = {
      type = "github";
      owner = "ehllie";
      repo = "ez-configs";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-parts.follows="flakeParts";
      };
    };
    #TODO: Add agenix


#| Other Utilities
    flakeCompat = {
      type = "github";
      owner = "edolstra";
      repo = "flake-compat";
      flake = false;
    };
    # nixDeploy = {
    #   type = "github";
    #   owner = "serokell";
    #   repo = "deploy-rs";
    #   inputs = {
    #     nixpkgs.follows = "nixosUnstable";
    #   };
    # };

    #| Templates
    # nixed = {
    #   # url = "github:Craole/nixed";
    #   type = "github";
    #   owner = "Craole";
    #   repo = "nixed";
    #   inputs = {
    #     The-Nix-Way.nixpkgs.follows = "nixosUnstable";
    #     # flake-parts.follows = "flakeParts";
    #     # treefmt-nix.follows = "treeFormatter";
    #     # nix-github-actions.follows = "nixGitActions";
    #   };
    # };

    # haumea = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "haumea";
    # };



    #| Core
    # nixpkgs = {
    #   url = "nixpkgs/nixos-unstable";
    # };
    # homeManager = {
    #   url = "github:nix-community/home-manager";
    #   inputs = {
    #     nixpkgs.follows ="nixosUnstable";
    #   };
    # };

    #| Utilities
    # flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-unified.url = "github:srid/nixos-unified";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows ="nixosUnstable";
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
    #     nixpkgs.follows ="nixosUnstable";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";

    #| Neovim
    # nixvim = {
    #   url = "github:nix-community/nixvim";
    #   inputs.nixpkgs.follows ="nixosUnstable";
    # };

    # Devshell
    # git-hooks = {
    #   url = "github:cachix/git-hooks.nix";
    #   flake = false;
    # };
  };
}
