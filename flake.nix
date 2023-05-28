{
  ## ensure a successful installation by pinning nixpkgs to a known
  ## good revision
  #inputs.nixpkgs.url = "github:nixos/nixpkgs/c8f6370f7daf435d51d137dcbd80c7ebad1f21f2";
  ## after reboot, you can track latest stable by using
  #inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
  ## or track rolling release by using
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }@inputs:
    let
      lib = nixpkgs.lib;
      mkHost = { my-config, zfs-root, pkgs, system, ... }:
        lib.nixosSystem {
          inherit system;
          pkgs.config.allowUnfree = true;
          modules = [
            ./modules
            (import ./configuration.nix {
              inherit my-config zfs-root inputs pkgs lib;
            })
          ];
        };
    in {
      nixosConfigurations = {
        exampleHost = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in mkHost (import ./hosts/exampleHost { inherit system pkgs; });
        
        a3k = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in mkHost (import ./hosts/a3k { inherit system pkgs; });
      };
    };
}
