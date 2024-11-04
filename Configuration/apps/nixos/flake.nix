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
      # CORE = import ./core { inherit inputs; };
      # inherit (CORE) libs;
      # DOTS = {
      #   inherit inputs libs;
      #   flake = {
      #     homePath = libs.extended.filesystem.locateFlakeRoot;
      #     storePath = ./.;
      #   };
      # };

      coreModules = [ ./core ];
      homeModules = [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "bac";
            # extraSpecialArgs = DOTS;

            useGlobalPkgs = true;
            useUserPackages = true;
            # users.craole.imports = [ ./home ];
          };
        }
      ];
    in
    {
      # inherit DOTS;

      nixosConfigurations = {
        preci = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = coreModules ++ homeModules;
        };
        dbook = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "./imports/dbook"
          ] ++ coreModules ++ homeModules;
        };
      };
    };
}
