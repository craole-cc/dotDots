{
  description = "NixOS WSL Flake for QBXL";

  inputs = {
    nixosPkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
    nixosHome = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      inputs.nixpkgs.follows = "nixosPkgs";
    };
    nixosWSL = {
      type = "github";
      owner = "nix-community";
      repo = "NixOS-WSL";
      inputs = {
        nixpkgs.follows = "nixosPkgs";
        flake-compat.follows = "flakeCompat";
      };
    };
    flakeCompat = {
      type = "github";
      owner = "edolstra";
      repo = "flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixosPkgs,
      nixosWSL,
      nixosHome,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixosPkgs.legacyPackages.${system};
      nixos-rebuild-QBXL = pkgs.writeShellScriptBin "QBXL" ''
        # Exit immediately if any command fails
        set -e
        printf "NixOS WSL Flake for QBXL\n"

        printf "Updating...\n"
        nix flake update --commit-lock-file "${self}"

        printf "Rebuilding...\n"
        sudo nixos-rebuild switch --flake "${self}" --show-trace --upgrade
      '';
    in
    {
      nixosConfigurations.QBXL = nixosPkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixosWSL.nixosModules.default
          nixosHome.nixosModules.home-manager
          ./core
          ./home
          ./options

          {
            networking = {
              hostName = "QBXL";
              hostId = with builtins; substring 0 8 (hashString "md5" "QBXL");
            };
            environment.systemPackages = [ nixos-rebuild-QBXL ];
          }
        ];
      };

      scripts.nixos-rebuild-QBXL = nixos-rebuild-QBXL;
    };
}
