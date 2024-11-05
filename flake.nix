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
      modules = ./Configuration/apps/nixos;
      # hostModules = modules + "/hosts";
      coreModules = [ modules ] ++ homeModules;
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
          modules = coreModules ++ [
            {
              # DOTS.hosts.Preci.enable = true;
            }
          ];
        };

        dbook = nixosSystem {
          system = "x86_64-linux";
          modules = coreModules ++ [ { DOTS.hosts.DBook.enable = true; } ];
          # modules = [ (hostModules + "/dbook") ] ++ coreModules;
        };
      };

      darwinConfigurations = {
        MBPoNine = darwinSystem {
          system = "x86_64-darwin";
          modules = homeModules ++ [ { DOTS.hosts.MBPoNine.enable = true; } ];
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
