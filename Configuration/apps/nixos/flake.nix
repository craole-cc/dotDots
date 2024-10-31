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
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      libs = import ./libraries { inherit inputs; };
      DOTS = {
        inherit inputs;
        flakeHome = libs.extended.filesystem.locateProjectRoot;
        flakePath = ./.;
        libs = libs;
      };
    in
    {
      inherit DOTS;

      nixosConfigurations = {
        preci = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # ./core
            # ./libraries
            # ./options/core        # ./options/libraries
            # ./configurations/core

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "bac";
                extraSpecialArgs = DOTS;

                useGlobalPkgs = true;
                useUserPackages = true;
                # users.craole.imports = [ ./home ];
              };
            }
          ];
          specialArgs = DOTS;
        };
      };
    };
}
