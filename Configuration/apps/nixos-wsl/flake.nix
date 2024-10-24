{
  description = "NixWSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    treefmt.url = "github:numtide/treefmt-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs:
    with inputs; let
      system = "x86_64-linux";
      hostname = "victus";
      username = "craole";
      # secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");
      secrets = builtins.fromJSON (builtins.readFile "${self}/.env");

      nixpkgsWithOverlays = system: (import nixpkgs rec {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [];
        };

        overlays = [
          nur.overlay

          (_final: prev: {
            unstable = import nixpkgs-unstable {
              inherit (prev) system;
              inherit config;
            };
          })
        ];
      });

      configurationDefaults = args: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = args;
        };
      };

      specialArgs = {
        inherit secrets inputs self nix-index-database hostname username;
        channels = {
          inherit nixpkgs nixpkgs-unstable;
        };
      };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      # formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      nixosConfigurations."${hostname}" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        pkgs = nixpkgsWithOverlays system;
        modules = [
          # "${modulesPath}/profiles/minimal.nix"
          nixos-wsl.nixosModules.wsl
          ./wsl.nix
          (configurationDefaults specialArgs)
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
