{
  description = "NixOS Configuration Flake";
  outputs =
    inputs@{
      self,
      ...
    }:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.darwin.lib) darwinSystem;
      inherit (inputs.home-manager.nixosModules) home-manager;
      coreModules = [
        ./Configuration/apps/nixos
      ] ++ homeModules;
      homeModules = [
        home-manager
        {
          home-manager = {
            backupFileExtension = "BaC";
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
      ];
    in
    {
      nixosConfigurations = {
        preci = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules;
        };

        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules;
        };
      };

      darwinConfigurations = {
        MBPoNine = darwinSystem {
          system = "x86_64-darwin";
          modules = homeModules;
        };
      };
    };
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixed = {
      url = "github:Craole/nixed";
      flake = false;
    };
  };
}
