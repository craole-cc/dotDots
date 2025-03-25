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
          gitHooks.flakeModule
          gitIgnore.flakeModule
          secretKey.flakeModule
          secretShell.flakeModule
          treeFormatter.flakeModule
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
            pkgs,
            self',
            lib,
            system,
            ...
          }:
          {
            _module.args = {
              pkgs = inputs'.nixpkgs.legacyPackages;
            };

            devshells.default = {
              env = [
                {
                  name = "HTTP_PORT";
                  value = 8080;
                }
              ];
              commands = [
                {
                  help = "print hello";
                  name = "hello";
                  command = "echo hello";
                }
              ];
              packages = with pkgs; [
                cowsay
              ];
            };
            # devShells =
            #   let
            #     inherit (pkgs.devshell) mkShell importTOML;
            #     inherit (paths.devShells)
            #       dots
            #       dev
            #       media
            #       env
            #       ;
            #   in
            #   {
            #     default = mkShell {
            #       imports = [
            #         (importTOML dots)
            #         # (importTOML dev)
            #         # (importTOML media)
            #         # (importTOML env)
            #       ];
            #     };
            #   };
            #   checks =
            #     let
            #       machinesPerSystem = {
            #         aarch64-linux = [
            #           "Raspi"
            #         ];
            #         x86_64-linux = [
            #           "QBX"
            #           "dbook"
            #           "Preci"
            #         ];
            #       };

            #       nixosMachines = lib.mapAttrs' (n: lib.nameValuePair "nixos-${n}") (
            #         lib.genAttrs (machinesPerSystem.${system} or [ ]) (
            #           name: self.nixosConfigurations.${name}.config.system.build.toplevel
            #         )
            #       );

            #       blacklistPackages = [
            #         "install-iso"
            #         "nspawn-template"
            #         "netboot-pixie-core"
            #         "netboot"
            #       ];

            #       packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") (
            #         lib.filterAttrs (n: _v: !(builtins.elem n blacklistPackages)) self'.packages
            #       );

            #       devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;

            #       homeConfigurations = lib.mapAttrs' (
            #         name: config: lib.nameValuePair "home-manager-${name}" config.activation-script
            #       ) (self'.legacyPackages.homeConfigurations or { });
            #     in
            #     nixosMachines // packages // devShells // homeConfigurations;
          };
      }
    );

  inputs = {
    #| NixOS Packages
    nixosStable = {
      # url = "nixpkgs/nixos-24-11";
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-24.11";
    };
    nixosUnstable = {
      # url = "nixpkgs/nixos-unstable";
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
    # nixosRolling={

    #   type = "github";
    #   owner = "cachix";
    #   repo = "devenv";

    # };
    #TODO: Add vscode ext

    #| Flake Parts (https://flake.parts)
    flakeParts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs = {
        nixpkgs-lib.follows = "nixLib";
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
        flake-parts.follows = "flakeParts";
        nixpkgs.follows = "nixosUnstable";
      };
    };
    secretManager = {
      type = "github";
      owner = "ryantm";
      repo = "agenix";
      inputs = {
        darwin.follows = "nixosDarwin";
        home-manager.follows = "nixosHome";
        nixpkgs.follows = "nixosUnstable";
        systems.follows = "nixosSystems";
      };
    };
    secretKey = {
      type = "github";
      owner = "oddlama";
      repo = "agenix-rekey";
      inputs = {
        devshell.follows = "developmentShell";
        nixpkgs.follows = "nixosUnstable";
        flake-parts.follows = "flakeParts";
        pre-commit-hooks.follows = "gitHooks";
        treefmt-nix.follows = "treeFormatter";
      };
    };
    secretShell = {
      type = "github";
      owner = "aciceri";
      repo = "agenix-shell";
      inputs = {
        flake-parts.follows = "flakeParts";
        flake-root.follows = "flakeRoot";
        git-hooks-nix.follows = "gitHooks";
        nix-github-actions.follows = "githubActions";
        nixpkgs.follows = "nixosUnstable";
        treefmt-nix.follows = "treeFormatter";
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

    #| Utilities by Cachix
    # nixCache = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "cachix";
    #   ref = "latest";
    #   inputs = {
    #     devenv.follows = "developmentEnvironment";
    #     flake-parts.follows = "flakeParts";
    #     flake-compat.follows = "flakeCompat";
    #     git-hooks.follows = "gitHooks";
    #     nixpkgs.follows = "nixosUnstable";
    #   };
    # };
    gitHooks = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        gitignore.follows = "gitIgnore";
        flake-compat.follows = "flakeCompat";
      };
    };
    # developmentEnvironment = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "devenv";
    #   inputs = {
    #     nixpkgs.follows = "nixosUnstable";
    #     flake-compat.follows = "flakeCompat";
    #     git-hooks.follows = "gitHooks";
    #     cachix.follows = "nixCache";
    #     nix.follows = "nixDevEnv";

    #     nixpkgs-23-11.follows = "";
    #     nixpkgs-regression.follows = "";
    #   };
    # };

    #| Utilities
    flakeRoot = {
      type = "github";
      owner = "srid";
      repo = "flake-root";
    };
    flakeCompat = {
      type = "github";
      owner = "edolstra";
      repo = "flake-compat";
      flake = false;
    };
    nixosHardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
    };
    nixosDarwin = {
      type = "github";
      owner = "lnl7";
      repo = "nix-darwin";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    nixosSystems = {
      type = "github";
      owner = "nix-systems";
      repo = "default";
    };

    #| Utilities by NixCommunity
    # nixCache = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "harmonia";
    #   inputs = {
    #     nixpkgs.follows = "nixosUnstable";
    #     flake-parts.follows = "flakeParts";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };
    # nixDisk = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "disko";
    #   inputs.nixpkgs.follows = "nixosUnstable";
    # };
    nixosHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixosUnstable";
    };
    # nixImpermanence = {
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
    # nixLocate = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "nix-index-database";
    #   inputs = {
    #     nixpkgs.follows = "nixosUnstable";
    #   };
    # };
    # nixLocateLocal = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "nix-index";
    #   inputs = {
    #     nixpkgs.follows = "nixosUnstable";
    #     flake-compat.follows = "flakeCompat";
    #   };
    # };
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
    nixosWSL = {
      type = "github";
      owner = "nix-community";
      repo = "NixOS-WSL";
      inputs = {
        nixpkgs.follows = "nixosUnstable";
        flake-compat.follows = "flakeCompat";
      };
    };

    #| Templates
    templatesNixOS = {
      type = "github";
      owner = "NixOS";
      repo = "templates";
    };
    templatesTheNixWay = {
      type = "github";
      owner = "the-nix-way";
      repo = "dev-templates";
      inputs.nixpkgs.follows = "nixosUnstable";
    };

    #TODO: Add my templates, uncouple them from NixOS and TheNixWay
    # templatesNixed = {
    #   # url = "github:Craole/nixed";
    #   type = "github";
    #   owner = "Craole";
    #   repo = "nixed";
    # };

    #| Utilities
    # flake-parts.url = "github:hercules-ci/flake-parts";
    # nixos-unified.url = "github:srid/nixos-unified";
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
  };
}
