{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixosCore) lib legacyPackages;
    inherit (import src {inherit lib src;}) lix hosts schema;
    inherit (lix) getSystems mkCore;
    inherit (getSystems {inherit hosts legacyPackages;}) perFlake;

    inputModules = with inputs; {
      core = {
        # age = secretManager.nixosModules.default;
        home-manager = nixosHome.nixosModules.default;
        nix-index = nixLocate.nixosModules.default;
        nvf = neoVim.nixosModules.default;
      };
      home = {
        noctalia-shell = shellNoctalia.homeModules.default;
        dankMaterialShell = shellDankMaterial.homeModules.dankMaterialShell.default;
        # inherit (niri.homeModules) niri; # Outdated
        nvf = neoVim.homeManagerModules.default;
        plasma-manager = plasma.homeModules.plasma-manager;
        zen-browser = firefoxZen.homeModules.twilight;
      };
    };

    specialArgs = {
      flake = self;
      inherit inputModules lix schema;
    };

    perSystem = perFlake (
      {
        system,
        pkgs,
      }: {
        devShells = import ./Packages/cli {
          inherit
            pkgs
            lib
            lix
            src
            system
            ;
        };
      }
    );

    forSystem = {
      nixosConfigurations = mkCore {inherit hosts specialArgs;};
    };
  in
    perSystem // forSystem;

  inputs = {
    nixosCore.url = "nixpkgs/nixos-unstable";
    #~@ NixOS Official
    # nixosCore = {
    #   repo = "nixos-unstable";
    #   owner = "nixpkgs";
    #   type = "github";
    # };

    #~@ Utilities by NixCommunity
    nixosHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    # nixosWSL = {
    #   repo = "NixOS-WSL";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     flake-compat.follows = "flakeCompat";
    #   };
    # };

    # nixCache = {
    #   repo = "harmonia";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     flake-parts.follows = "flakeParts";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };

    # nixDisk = {
    #   repo = "disko";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixosCore";
    # };

    # nixImpermanence = {
    #   repo = "impermanence";
    #   owner = "nix-community";
    #   type = "github";
    # };

    nixLocate = {
      repo = "nix-index-database";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    # nixLib = {
    #   repo = "nixpkgs.lib";
    #   owner = "nix-community";
    #   type = "github";
    # };

    # nixUnitTesting = {
    #   repo = "nix-unit";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     flake-parts.follows = "flakeParts";
    #     treefmt-nix.follows = "treeFormatter";
    #     nix-github-actions.follows = "githubActions";
    #   };
    # };

    # githubActions = {
    #   repo = "nix-github-actions";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixosCore";
    # };

    # NUR = {
    #   repo = "NUR";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs = {
    #     flake-parts.follows = "flakeParts";
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    #~@ Flake Parts (https://flake.parts)
    flakeParts = {
      repo = "flake-parts";
      owner = "hercules-ci";
      type = "github";
      inputs = {
        nixpkgs-lib.follows = "nixLib";
      };
    };

    # developmentShell = {
    #   repo = "devshell";
    #   owner = "numtide";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # gitIgnore = {
    #   owner = "hercules-ci";
    #   repo = "gitignore.nix";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # configHosts = {
    #   repo = "easy-hosts";
    #   owner = "tgirlcloud";
    #   type = "github";
    # };

    # configNixos = {
    #   repo = "ez-configs";
    #   type = "github";
    #   owner = "ehllie";
    #   inputs = {
    #     flake-parts.follows = "flakeParts";
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # secretManager = {
    #   type = "github";
    #   owner = "ryantm";
    #   repo = "agenix";
    #   inputs = {
    #     darwin.follows = "nixosDarwin";
    #     home-manager.follows = "nixosHome";
    #     nixpkgs.follows = "nixosCore";
    #     systems.follows = "nixosSystems";
    #   };
    # };

    # secretKey = {
    #   repo = "agenix-rekey";
    #   owner = "oddlama";
    #   type = "github";
    #   inputs = {
    #     devshell.follows = "developmentShell";
    #     nixpkgs.follows = "nixosCore";
    #     flake-parts.follows = "flakeParts";
    #     pre-commit-hooks.follows = "gitHooks";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };

    # secretShell = {
    #   owner = "aciceri";
    #   repo = "agenix-shell";
    #   type = "github";
    #   inputs = {
    #     flake-parts.follows = "flakeParts";
    #     flake-root.follows = "flakeRoot";
    #     git-hooks-nix.follows = "gitHooks";
    #     nix-github-actions.follows = "githubActions";
    #     nixpkgs.follows = "nixosCore";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    #~@ Utilities by Cachix
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
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # gitHooks = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "git-hooks.nix";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     gitignore.follows = "gitIgnore";
    #     flake-compat.follows = "flakeCompat";
    #   };
    # };
    # developmentEnvironment = {
    #   type = "github";
    #   owner = "cachix";
    #   repo = "devenv";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     flake-compat.follows = "flakeCompat";
    #     git-hooks.follows = "gitHooks";
    #     cachix.follows = "nixCache";
    #     # nix.follows = "nixDevEnv";
    #   };
    # };

    #~@ Utilities
    # flakeRoot = {
    #   type = "github";
    #   owner = "srid";
    #   repo = "flake-root";
    # };

    flakeCompat = {
      repo = "flake-compat";
      owner = "edolstra";
      type = "github";
      flake = false;
    };

    # flakeUtils = {
    #   repo = "flake-utils";
    #   owner = "numtide";
    #   type = "github";
    #   inputs = {
    #     systems.follows = "nixosSystems";
    #   };
    # };

    # nixosHardware = {
    #   repo = "nixos-hardware";
    #   owner = "NixOS";
    #   type = "github";
    # };

    # nixosDarwin = {
    #   repo = "nix-darwin";
    #   owner = "lnl7";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixosCore";
    # };

    # nixosSystems = {
    #   repo = "default";
    #   owner = "nix-systems";
    #   type = "github";
    # };

    #~@ Templates
    # templatesNixOS = {
    #   repo = "templates";
    #   owner = "NixOS";
    #   type = "github";
    # };

    # templatesTheNixWay = {
    #   repo = "dev-templates";
    #   owner = "the-nix-way";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # templatesNixed = {
    #   repo = "nixed";
    #   owner = "Craole";
    #   type = "github";
    # };

    #~@ Home
    plasma = {
      repo = "plasma-manager";
      owner = "pjones";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };

    # styleManager = {
    #   owner = "danth";
    #   repo = "stylix";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     systems.follows = "nixosSystems";
    #     flake-parts.follows = "flakeParts";
    #     nur.follows = "NUR";
    #   };
    # };

    # nixos-unified.url = "github:srid/nixos-unified";
    # nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    #~@ Software inputs
    firefoxZen = {
      owner = "0xc000022070";
      repo = "zen-browser-flake";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };

    neoVim = {
      owner = "notashelf";
      repo = "nvf";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        systems.follows = "nixosSystems";
        flake-compat.follows = "flakeCompat";
        flake-parts.follows = "flakeParts";
      };
    };

    # TODO: Enable when this gets updated
    # niri = {
    #   owner = "sodiboo";
    #   repo = "niri-flake";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #   };
    # };

    # quickShell = {
    #   url = "github:outfoxxed/quickshell";
    #   inputs.nixpkgs.follows = "nixosCore";
    # };

    shellNoctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixosCore";
    };

    shellDankMaterial = {
      # url = "github:AvengeMedia/DankMaterialShell/stable";
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixosCore";
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
    #     nixpkgs.follows ="nixosCore";
    #     home-manager.follows = "homeManager";
    #   };
    # };
    # stylix.url = "github:danth/stylix";
    #TODO: Add vscode ext
  };
}
