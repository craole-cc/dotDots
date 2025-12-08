{
  description = "NixOS Configuration for Victus";

  outputs = inputs @ {self, ...}:
    with inputs; let
      inherit (nixosCore) lib;
      inherit (lib) nixosSystem;
      args = import ./_.nix {inherit lib;} // inputs // self // lib;
      inherit (args) systemName;

      mkSystem = hostName: let
        cfgHost = import ./api/hosts/${hostName};
        system = cfgHost.specs.platform;
        # args = {
        #   inherit inputs sel lib;
        #   DOM = "_";
        # };
      in
        nixosSystem {
          inherit system;
          modules = [./.];
          specialArgs = args;
        };
    in {
      nixosConfigurations.${systemName} = mkSystem systemName;
    };

  inputs = {
    #| NixOS
    nixosCore.url = "nixpkgs/nixos-unstable";

    #| Utilities by NixCommunity
    nixosHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };
    nixUserRepo = {
      owner = "nix-community";
      repo = "NixOS-WSL";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        flake-compat.follows = "flakeCompat";
      };
    };
    ghActions = {
      repo = "nix-github-actions";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };
    nixLocate = {
      repo = "nix-index-database";
      owner = "nix-community";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };
    nixLib = {
      repo = "nixpkgs.lib";
      owner = "nix-community";
      type = "github";
    };
    nixUnitTesting = {
      repo = "nix-unit";
      owner = "nix-community";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        flake-parts.follows = "flakeParts";
        treefmt-nix.follows = "treeFormatter";
        nix-github-actions.follows = "ghActions";
      };
    };
    nixosWSL = {
      repo = "NixOS-WSL";
      owner = "nix-community";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        flake-compat.follows = "flakeCompat";
      };
    };

    #| Flake Parts (https://flake.parts)
    flakeParts = {
      repo = "flake-parts";
      owner = "hercules-ci";
      type = "github";
      inputs = {
        nixpkgs-lib.follows = "nixLib";
      };
    };
    developmentShell = {
      repo = "devshell";
      owner = "numtide";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };
    gitIgnore = {
      owner = "hercules-ci";
      repo = "gitignore.nix";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
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
        nixpkgs.follows = "nixosCore";
      };
    };
    secretManager = {
      type = "github";
      owner = "ryantm";
      repo = "agenix";
      inputs = {
        darwin.follows = "nixosDarwin";
        home-manager.follows = "nixosHome";
        nixpkgs.follows = "nixosCore";
        systems.follows = "nixosSystems";
      };
    };
    secretKey = {
      type = "github";
      owner = "oddlama";
      repo = "agenix-rekey";
      inputs = {
        devshell.follows = "developmentShell";
        nixpkgs.follows = "nixosCore";
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
        nix-github-actions.follows = "ghActions";
        nixpkgs.follows = "nixosCore";
        treefmt-nix.follows = "treeFormatter";
      };
    };
    treeFormatter = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    #| Utilities by Cachix
    gitHooks = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixosCore";
        gitignore.follows = "gitIgnore";
        flake-compat.follows = "flakeCompat";
      };
    };

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
      owner = "numtide";
      repo = "flake-utils";
      type = "github";
      inputs.systems.follows = "nixosSystems";
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
      inputs.nixpkgs.follows = "nixosCore";
    };
    nixosSystems = {
      type = "github";
      owner = "nix-systems";
      repo = "default";
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
      inputs.nixpkgs.follows = "nixosCore";
    };

    #| Home
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };
    styleManager = {
      owner = "danth";
      repo = "stylix";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        systems.follows = "nixosSystems";
        flake-parts.follows = "flakeParts";
        nur.follows = "nixUserRepo";
      };
    };

    #| Software inputs
    zenBrowser = {
      owner = "0xc000022070";
      repo = "zen-browser-flake";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };
  };
}
