{
  inputs = {
    nixpkgs = {
      # url = "github:nixos/nixpkgs/nixos-unstable";
      url = "github:nixos/nixpkgs/nixos-22.11";
    };
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

        # nixpkgs.config.allowUnfree = true;

        modules = [
          ./Global/Modules
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
      #  mkHost (import ./Clients/exampleHost {inherit system pkgs;});

      a3k = let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
      in
        mkHost (import ./Clients/a3k {inherit system pkgs;});
    };
  };
}
