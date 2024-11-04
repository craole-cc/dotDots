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
  outputs = inputs@{ self, ... }:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem;
      inherit (inputs.home-manager.nixosModules) home-manager;
      mods = {
        core = [
          ./core/libraries
          ./core/options
        ];
        home = [
          ./home/libraries
          ./home/options
        ];
        craole = [
          ./home/configurations/craole
        ] ++ mods.home;
      };
      coreModules = mods.core;
      homeModules = [
        home-manager
        {
          home-manager = {
            backupFileExtension = "BaC";
            useGlobalPkgs = true;
            useUserPackages = true;
            users.craole.imports = mods.craole;
          };
        }
      ];
    in
    {
      nixosConfigurations = {
        preci = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules ++ homeModules;
        };
        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./core/hosts/dbook
          ] ++ coreModules ++ homeModules;
        };
      };
    };
}
