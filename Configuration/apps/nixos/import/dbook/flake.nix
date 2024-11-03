{
  description = "NixOS Configuration Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        preci = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./core
            # ./libraries
            # ./options/core        # ./options/libraries
            # ./configurations/core

            # home-manager.nixosModules.home-manager
            # {
            #   home-manager = {
            #     backupFileExtension = "bac";
            #     extraSpecialArgs = DOTS;

            #     useGlobalPkgs = true;
            #     useUserPackages = true;
            #     # users.craole.imports = [ ./home ];
            #   };
            # }
          ];
        };
      };
    };
}
