{
  description = "NixOS Configuration Flake";
  outputs =
    inputs@{ self, nixPackages, ... }:
    let
      dots = import ./default.nix;
      # inherit (self) outputs;
      inherit (nixPackages) lib;
      inherit (lib) genAttrs;
      inherit (dots) paths;

      systems = genAttrs (import inputs.nixosSystems);
      perSystem = x: systems (system: x perSystemPackages.${system});
      perSystemPackages = systems (system: import nixPackages { inherit system; });
    in
    {
      overlays = import paths.packages.overlays { inherit inputs; };
      packages = perSystem (system: import paths.packages.custom nixPackages.legacyPackages.${system});
    };

  inputs = {
    #| NixOS
    nixPackages.url = "nixpkgs/nixos-unstable";
    nixPackagesStable.url = "nixpkgs/nixos-24.11";

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
    # nixLocate = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "nix-index-database";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
    #   };
    # };
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
    # plasmaManager = {
    #   url = "github:pjones/plasma-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";
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
  };
}
