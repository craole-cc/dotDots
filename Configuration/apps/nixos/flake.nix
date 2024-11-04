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
      mods = {
        core =
          [
            ./core/libraries
            ./core/options
          ]
          ++ [
            home-manager
            {
              home-manager = {
                backupFileExtension = "BaC";
                useGlobalPkgs = true;
                useUserPackages = true;
                # users.craole.imports = mods.home ++ [
                #   ./home/configurations/craole
                # ];
              };
            }
          ];
        home = [
          ./home/libraries
          ./home/options
        ];
      };
    in
    {
      nixosConfigurations = {
        preci = nixosSystem {
          system = "x86_64-linux";
          modules = mods.core ++ [ ./core/configurations/preci ];
        };
        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = mods.core ++ [ ./core/configurations/dbook ];
        };
      };
    };
}
