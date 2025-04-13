{
  description = "dotDots Flake Configuration";
  outputs =
    inputs@{ self, nixPackages, ... }:
    let
      inherit (nixPackages) lib;
      inherit (lib.attrsets) genAttrs attrValues;
      inherit (lib.modules) evalModules;

      systems = genAttrs (import inputs.nixosSystems);
      paths = (evalModules { modules = [ { imports = [ ./. ]; } ]; }).config.DOTS.paths;
      packageOverlays = import paths.pkgs.overlays { inherit inputs; };
      perSystemPackages = systems (
        system:
        import nixPackages {
          inherit system;
          overlays = attrValues packageOverlays;
          config.allowUnfree = true;
        }
      );
      perSystem = x: systems (system: x perSystemPackages.${system});
      packages = perSystem (pkgs: import paths.pkgs.custom { inherit pkgs paths; });
      mkHost =
        name: args:
        import paths.libs.mkHost {
          inherit
            inputs
            paths
            self
            # lib
            ;
        } name args;
    in
    {
      inherit packages lib;

      overlays = packageOverlays;

      devShells = perSystem (pkgs: {
        default = packages.${pkgs.system}.dotshell;
      });

      formatter = perSystem (pkgs: pkgs.treefmt); # TODO: Maybe we should still use treefmt-nix. Either way we need to define the formatter packages and make them available system-wide (devshells and modules). Also how can I make the treefmt.toml be available system-wide, not just in the devshells/project?

      nixosConfigurations = {
        QBXvm = mkHost "QBXvm" { };
        # QBXvm = mkHost {
        #   hostName = "QBXvm";
        #   extraModules = with dots; [
        #     (paths.hosts + "/QBXvm")
        #     modules.core
        #     modules.home
        #   ];
        # };

        # QBXl = mkHost {
        #   hostName = "QBXl";
        #   extraModules = [
        #     dots.modules.wsl
        #   ];
        # };
      };
    };

  inputs = {
    #| NixOS
    nixPackages.url = "nixpkgs/nixos-unstable";
    nixPackagesStable.url = "nixpkgs/nixos-24.11";
    nixPackagesUnstable.url = "nixpkgs/nixos-unstable";

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
        nixpkgs.follows = "nixPackages";
      };
    };
    gitIgnore = {
      owner = "hercules-ci";
      repo = "gitignore.nix";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };
    configHosts = {
      type = "github";
      owner = "tgirlcloud";
      repo = "easy-hosts";
    };
    configNixos = {
      type = "github";
      owner = "ehllie";
      repo = "ez-configs";
      inputs = {
        flake-parts.follows = "flakeParts";
        nixpkgs.follows = "nixPackages";
      };
    };
    secretManager = {
      type = "github";
      owner = "ryantm";
      repo = "agenix";
      inputs = {
        darwin.follows = "nixosDarwin";
        home-manager.follows = "nixosHome";
        nixpkgs.follows = "nixPackages";
        systems.follows = "nixosSystems";
      };
    };
    secretKey = {
      type = "github";
      owner = "oddlama";
      repo = "agenix-rekey";
      inputs = {
        devshell.follows = "developmentShell";
        nixpkgs.follows = "nixPackages";
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
        nixpkgs.follows = "nixPackages";
        treefmt-nix.follows = "treeFormatter";
      };
    };
    treeFormatter = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs = {
        nixpkgs.follows = "nixPackages";
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
    #     nixpkgs.follows = "nixPackages";
    #   };
    # };
    gitHooks = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixPackages";
        gitignore.follows = "gitIgnore";
        flake-compat.follows = "flakeCompat";
      };
    };
    # developmentEnvironment = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "devenv";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
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
    flakeUtils = {
      # url = "github:numtide/flake-utils";
      owner = "numtide";
      repo = "flake-utils";
      type = "github";
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
      inputs.nixpkgs.follows = "nixPackages";
    };
    nixosSystems = {
      type = "github";
      owner = "nix-systems";
      repo = "default";
    };

    #| Utilities by NixCommunity
    nur = {
      owner = "nix-community";
      repo = "NixOS-WSL";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        flake-compat.follows = "flakeCompat";
      };
    };
    # nixCache = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "harmonia";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
    #     flake-parts.follows = "flakeParts";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };
    # nixDisk = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "disko";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };
    nixosHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixPackages";
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
      inputs.nixpkgs.follows = "nixPackages";
    };
    nixLocate = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index-database";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };
    # nixLocateLocal = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "nix-index";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
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
        nixpkgs.follows = "nixPackages";
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
        nixpkgs.follows = "nixPackages";
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
      inputs.nixpkgs.follows = "nixPackages";
    };

    #TODO: Add my templates, uncouple them from NixOS and TheNixWay
    # templatesNixed = {
    #   # url = "github:Craole/nixed";
    #   type = "github";
    #   owner = "Craole";
    #   repo = "nixed";
    # };

    #| Home
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixosHome";
      };
    };
    styleManager = {
      # url = "github:danth/stylix";
      owner = "danth";
      repo = "stylix";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        systems.follows = "nixosSystems";
        flake-compat.follows = "flakeCompat";
        flake-utils.follows = "flakeUtils";
        git-hooks.follows = "gitHooks";
        home-manager.follows = "nixosHome";
        nur.follows = "nur";
      };
    };
    # nixos-unified.url = "github:srid/nixos-unified";
    # nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #| Software inputs
    zen-browser = {
      # url = "github:0xc000022070/zen-browser-flake";
      owner = "0xc000022070";
      repo = "zen-browser-flake";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixosHome";
      };
    };
    # github-nix-ci.url = "github:juspay/github-nix-ci";
    # nixos-vscode-server = {
    #   url = "github:nix-community/nixos-vscode-server";
    #   flake = false;
    # };
    # omnix.url = "github:juspay/omnix";
    # hyprland.url = "github:hyprwm/Hyprland/v0.46.2";
    # hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    # rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";

    # plasmaManager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs = {
    #     nixpkgs.follows ="nixPackages";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";
    #TODO: Add vscode ext
  };
}
