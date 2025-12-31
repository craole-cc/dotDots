{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    path = src;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit (import src {inherit lib src self;}) lix flake hosts schema;
    inherit (lix.modules.core) systems mkCore;
    inherit (systems {inherit hosts legacyPackages;}) perFlake;

    modules = {
      #~@ Core
      nixpkgs = lix.modules.inputs.nixpkgs {inherit path;};
      nixpkgs-stable = lix.modules.inputs.nixpkgs-stable {inherit path;};
      nixpkgs-unstable = lix.modules.inputs.nixpkgs-unstable {inherit path;};
      home-manager = lix.modules.inputs.home-manager {inherit path;};

      #~@ Applications
      dank-material-shell = lix.modules.inputs.dank-material-shell {inherit path;};
      fresh-editor = lix.modules.inputs.fresh-editor {inherit path;};
      helix = lix.modules.inputs.helix {inherit path;};
      noctalia-shell = lix.modules.inputs.noctalia-shell {inherit path;};
      nvf = lix.modules.inputs.nvf {inherit path;};
      plasma = lix.modules.inputs.plasma {inherit path;};
      treefmt = lix.modules.inputs.treefmt {inherit path;};
      vscode-insiders = lix.modules.inputs.vscode-insiders {inherit path;};
      zen-browser = lix.modules.inputs.zen-browser {inherit path;};
    };

    packages = {
      #~@ Core
      nixpkgs-stable = modules.nixpkgs-stable.legacyPackages;
      nixpkgs-unstable = modules.nixpkgs-unstable.legacyPackages;
      home-manager = modules.home-manager.packages;

      #~@ Applications
      dank-material-shell = modules.dank-material-shell.packages;
      fresh-editor = modules.fresh-editor.packages;
      helix = modules.helix.packages;
      noctalia-shell = modules.noctalia-shell.packages;
      nvf = modules.nvf.packages;
      plasma = modules.plasma.packages;
      treefmt = modules.treefmt.packages;
      vscode-insiders = modules.vscode-insiders.packages;
      zen-browser = modules.zen-browser.packages;
    };

    args = {
      inherit lix flake schema src;
      inputs = {
        inherit modules packages;
        flake = inputs;
      };
    };

    perSystem = perFlake (
      {
        system,
        pkgs,
      }: {
        inherit
          (import ./Packages/global {
            inherit pkgs lib lix src system flake;
            inputs = args.inputs.packages;
          })
          devShells
          formatter
          checks
          ;
      }
    );
    forSystem =
      {nixosConfigurations = mkCore {inherit inputs hosts args src;};}
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
