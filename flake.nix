{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit (import src {inherit lib src self;}) lix flake hosts schema;
    inherit (lix.modules.core) systems mkSystem;
    inherit (systems {inherit hosts legacyPackages;}) perFlake;
    normalizedInputs = lix.inputs.normalize {path = src;};
    normalizedPackages = lix.inputs.normalizePackages {path = src;};
    args = {
      inherit lix flake schema src inputs normalizedInputs normalizedPackages;
    };

    perSystem = perFlake (
      {
        system,
        pkgs,
      }: {
        inherit
          (import ./Packages/global {
            inherit pkgs lib lix src system flake;
            inputs = normalizedPackages;
          })
          devShells
          formatter
          checks
          ;
      }
    );
    forSystem =
      {nixosConfigurations = mkSystem {inherit inputs hosts args src;};}
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

    browserZen = {
      repo = "zen-browser-flake";
      owner = "0xc000022070";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixHomeManager";
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

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };
  };
}
