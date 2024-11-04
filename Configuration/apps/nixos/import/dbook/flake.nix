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
      nixosConfigurations =
        let
          inherit (nixpkgs.lib) nixosSystem;
        in
        {
          preci = nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./configurations.nix
              # ./core
              # ./libraries
              # ./options/core        # ./options/libraries

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

          # dbook = nixosSystem {
          #   system = "x86_64-linux";
          #   modules = [

          #   ];
          # };
        };
    };
}
