{
  description = "Preci: NixOS (unstable) + Home Manager";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dots = {
      url = "github:craole-cc/dotDots";
      flake = false;
    };
    nix-index = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations.Preci = let
      args = {
        inherit inputs;
        system = "x86_64-linux";
      };
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit (args) system;
        specialArgs = args;
        modules = [./configuration.nix];
      };
  };
}
