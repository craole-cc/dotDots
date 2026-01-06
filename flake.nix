{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit
      (import src {inherit lib src self;})
      lix
      flake
      hosts
      schema
      ;
    inherit (lix.inputs.resolution) getInputs;
    inherit (lix.modules.generators.core) mkSystem;
    inherit (lix.modules.resolution) perFlake;

    args = {
      inherit
        lix
        flake
        schema
        src
        ;
    };

    perSystem = perFlake {inherit hosts legacyPackages;} (
      {
        system,
        pkgs,
      }: {
        inherit
          (import ./Packages/global {
            inherit pkgs lib lix src system flake;
            inputs = getInputs {inherit inputs;};
          })
          devShells
          formatter
          checks
          ;
      }
    );

    forSystem =
      {nixosConfigurations = mkSystem {inherit hosts args;};}
      // import ./Templates;
  in
    perSystem // forSystem;

  inputs = {
    nixPackages.url = "nixpkgs/nixos-unstable";
    nixPackagesUnstable.url = "nixpkgs/nixos-unstable";
    nixPackagesStable.url = "nixpkgs/nixos-25.11";

    nixHomeManager = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    nixDarwin = {
      repo = "nix-darwin";
      owner = "LnL7";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    nixChaotic = {
      ref = "nyxpkgs-unstable";
      repo = "nyx";
      owner = "chaotic-cx";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    browserZen = {
      repo = "zen-browser-flake";
      owner = "0xc000022070";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixHomeManager";
      };
    };

    editorAffinity = {
      repo = "affinity-nix";
      owner = "mrshmllow";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorHelix = {
      repo = "helix";
      owner = "helix-editor";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorFresh = {
      repo = "fresh";
      owner = "sinelaw";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorNeovim = {
      repo = "nvf";
      owner = "notashelf";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorTypix = {
      repo = "typix";
      owner = "loqusion";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorVscode = {
      repo = "vscode-insiders-nix";
      owner = "auguwu";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellDankMaterial = {
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellCaelestia = {
      repo = "shell";
      owner = "caelestia-dots";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellPlasma = {
      repo = "plasma-manager";
      owner = "pjones";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixHomeManager";
      };
    };

    shellQuick = {
      repo = "quickshell";
      owner = "outfoxxed";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    styleManager = {
      repo = "stylix";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };
  };
}
