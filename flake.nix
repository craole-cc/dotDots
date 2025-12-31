{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit (import src {inherit lib src self;}) lix flake hosts schema;
    inherit (lix.modules.core) systems mkCore;
    inherit (systems {inherit hosts legacyPackages;}) perFlake;

    args = {
      inherit lix flake schema src;
      rawInputs = inputs;
      inputs = {
        modules = with inputs; {
          core = {
            nixpkgs = nixPackages;
            # home-manager = nixHomeManager;
            home-manager = nixHomeManager.nixosModules.default;
            nvf = editorNeovim.nixosModules.default;
          };
          home = {
            noctalia-shell = shellNoctalia.homeModules.default;
            dank-material-shell = shellDankMaterial.homeModules.dank-material-shell;
            nvf = editorNeovim.homeManagerModules.default;
            plasma = shellPlasma.homeModules.plasma-manager;
            zen-browser = browserZen.homeModules.twilight;
            zen-homeModules = browserZen.homeModules;
          };
        };
        packages = with inputs; {
          dankMaterialShell = shellDankMaterial.packages;
          fresh-editor = editorFresh.packages;
          nixpkgs-stable = nixPackagesStable.legacyPackages;
          nixpkgs-unstable = nixPackagesUnstable.legacyPackages;
          noctalia-shell = shellNoctalia.packages;
          nvf = editorNeovim.packages;
          plasma-manager = shellPlasma.packages;
          vscode-insiders = inputs.editorVscode.packages;
          zen-browser = browserZen.packages;
        };
      };
    };

    perSystem = perFlake (
      {
        system,
        pkgs,
      }: {
        inherit
          (import ./Packages/shared {
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
