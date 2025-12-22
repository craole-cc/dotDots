{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixosCore) lib legacyPackages;
    inherit (import src {inherit lib src;}) lix hosts schema;
    inherit (lix) getSystems mkCore;
    inherit (getSystems {inherit hosts legacyPackages;}) pkgsFor perFlake;

    inputModules = with inputs; {
      core = {
        age = secretManager.nixosModules.default;
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

    # perSystem = perFlake ({
    #   system,
    #   pkgs,
    # }: {
    #   devShells = {
    #     default = (import src {inherit system pkgs lib src;}).shell;
    #     media = import ./Packages/cli/media.nix;
    #   };
    # });
    perSystem = perFlake ({
      system,
      pkgs,
    }: let
      shells = import ./Packages/cli {inherit pkgs lib lix src system;};
    in {
      devShells =
        shells
        // {
          default = shells.dots; # Set dots as default
        };
    });

    forSystem = {
      nixosConfigurations = mkCore {inherit hosts specialArgs;};
    };
  in
    perSystem // forSystem;

  inputs = {
    #| NixOS Official
    nixosCore.url = "nixpkgs/nixos-unstable";

    #| Utilities by NixCommunity
    nixosHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixosCore";
    };
    nixosWSL = {
      type = "github";
      owner = "nix-community";
      repo = "NixOS-WSL";
      inputs = {
        nixpkgs.follows = "nixosCore";
        flake-compat.follows = "flakeCompat";
      };
    };
    # nixCache = {
    #   type = "github";
    #   owner = "nix-community";
    #   repo = "harmonia";
    #   inputs = {
    #     nixpkgs.follows = "nixosCore";
    #     flake-parts.follows = "flakeParts";
    #     treefmt-nix.follows = "treeFormatter";
    #   };
    # };
    nixDisk = {
      type = "github";
      owner = "nix-community";
      repo = "disko";
      inputs.nixpkgs.follows = "nixosCore";
    };
    nixImpermanence = {
      type = "github";
      owner = "nix-community";
      repo = "impermanence";
    };
    nixLocate = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index-database";
      inputs = {
        nixpkgs.follows = "nixosCore";
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
        nixpkgs.follows = "nixosCore";
        flake-parts.follows = "flakeParts";
        treefmt-nix.follows = "treeFormatter";
        nix-github-actions.follows = "githubActions";
      };
    };
    githubActions = {
      type = "github";
      owner = "nix-community";
      repo = "nix-github-actions";
      inputs.nixpkgs.follows = "nixosCore";
    };
    NUR = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      inputs = {
        nixpkgs.follows = "nixosCore";
        flake-parts.follows = "flakeParts";
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
    developmentShell = {
      type = "github";
      owner = "numtide";
      repo = "devshell";
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
        nix-github-actions.follows = "githubActions";
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
      inputs = {
        systems.follows = "nixosSystems";
      };
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
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    # templatesNixed = {
    #   type = "github";
    #   owner = "Craole";
    #   repo = "nixed";
    # };

    #| Home
    plasma = {
      owner = "pjones";
      repo = "plasma-manager";
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

    #| Software inputs
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

    # TODO: Enable  when this gets updated
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
