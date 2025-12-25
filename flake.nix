{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixosCore) lib legacyPackages;
    inherit (import src {inherit lib src self;}) lix flake hosts schema;
    inherit (lix) getSystems mkCore;
    inherit (getSystems {inherit hosts legacyPackages;}) perFlake;

    specialArgs = {
      inherit lix flake schema;
      inputs = {
        modules = with inputs; {
          core = {
            home-manager = nixosHome.nixosModules.default;
            nvf = editorNeovim.nixosModules.default;
          };
          home = {
            noctalia-shell = shellNoctalia.homeModules.default;
            dankMaterialShell = shellDankMaterial.homeModules.dankMaterialShell.default;
            nvf = editorNeovim.homeManagerModules.default;
            plasma-manager = plasma.homeModules.plasma-manager;
            zen-browser = firefoxZen.homeModules.twilight;
            zen-homeModules = firefoxZen.homeModules;
          };
        };
        packages = with inputs; {
          dankMaterialShell = shellDankMaterial.packages;
          nixpkgs = nixosCore;
          noctalia-shell = shellNoctalia.packages;
          nvf = editorNeovim.packages;
          plasma-manager = plasma.packages;
          zen-browser = firefoxZen.packages;
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
            inputs = specialArgs.inputs.packages;
          })
          devShells
          formatter
          checks
          ;
      }
    );
    forSystem =
      {
        nixosConfigurations = mkCore {inherit hosts specialArgs;};
        # templates = let
        #   root = ./Templates;
        #   rust = {
        #     path = root + "/rust/standard";
        #     description = "Rust development environment with nightly toolchain";
        #   };
        #   rustspace = {
        #     path = root + "/rust/workspace";
        #     description = "Rust workspace with multiple crates";
        #   };
        # in {
        #   default = rust;
        #   inherit rust rustspace;
        # };
      }
      // import ./Templates;
  in
    perSystem // forSystem;

  inputs = {
    nixosCore.url = "nixpkgs/nixos-unstable";
    nixosHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    browserZen = {
      repo = "zen-browser-flake";
      owner = "0xc000022070";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };

    editorHelix = {
      repo = "helix";
      owner = "helix-editor";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    editorNeovim = {
      owner = "notashelf";
      repo = "nvf";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    shellDankMaterial = {
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
      };
    };

    shellPlasma = {
      repo = "plasma-manager";
      owner = "pjones";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };
  };
}
