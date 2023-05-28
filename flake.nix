{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
  } @ inputs: let
    lib = nixpkgs.lib;
    mkHost = {
      zfs-root,
      pkgs,
      system,
      ...
    }:
      lib.nixosSystem {
        inherit system;
        modules = [
          ./modules
          (import ./configuration.nix {
            inherit zfs-root inputs pkgs lib;
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
  in {
    nixosConfigurations = {
     # exampleHost = let
     #   system = "x86_64-linux";
     #   pkgs = nixpkgs.legacyPackages.${system};
     # in
     #  mkHost (import ./hosts/exampleHost {inherit system pkgs;});

      a3k = let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in
        mkHost (import ./hosts/a3k {inherit system pkgs;});
    };
  };
}
