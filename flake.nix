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
    # nixosCore.url = "nixpkgs/nixos-unstable";
    #~@ NixOS Official
    nixosCore = {
      repo = "nixos-unstable";
      owner = "nixpkgs";
      type = "github";
    };

    nixosHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    nixLocate = {
      repo = "nix-index-database";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };

    plasma = {
      repo = "plasma-manager";
      owner = "pjones";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixosCore";
        home-manager.follows = "nixosHome";
      };
    };

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

    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
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
  };
}
