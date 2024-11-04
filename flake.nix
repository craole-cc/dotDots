{
  description = "NixOS Configuration Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixed = {
    #   url = "github:Craole/nixed";
    #   flake = false;
    # };
  };
  outputs =
    inputs@{ self, ... }:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.home-manager.nixosModules) home-manager;
      src = ./Configuration/apps/nixos;
      mods = {
        core =
          [
            (src + "/core/libraries")
            (src + "/core/options")
          ]
          ++ [
            home-manager
            {
              home-manager = {
                backupFileExtension = "BaC";
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
          ];
        home = [
          (src + "/home/libraries")
          (src + "/home/options")
        ];
      };
    in
    {
      nixosConfigurations = {
        preci = nixosSystem {
          system = "x86_64-linux";
          modules = mods.core ++ [ (src + "/core/configurations/preci") ];
        };
        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = mods.core ++ [ (src + "/core/configurations/dbook") ];
        };
      };
    };
}
