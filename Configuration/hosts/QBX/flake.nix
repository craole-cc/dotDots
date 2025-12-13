{
  description = "NixOS configuration for QBX";

  outputs = inputs @ {self, ...}:
    with inputs; let
      args = {
        inherit self inputs;
        system = "x86_64-linux";
      };
    in {
      nixosConfigurations.QBX = nixosCore.lib.nixosSystem {
        inherit (args) system;
        specialArgs = args;
        modules = [./configuration.nix];
      };
    };

  inputs = {
    nixosCore.url = "nixpkgs/nixos-unstable";
    nixosHome = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixosCore";
    };
    flakeCompat = {
      type = "github";
      owner = "edolstra";
      repo = "flake-compat";
      flake = false;
    };
    firefoxZen = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixosCore";
    };
    plasmaManager = {
      url = "github:pjones/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixosHome";
      };
    };
  };
}
