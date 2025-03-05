{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      nixosConfigurations =
        flake-utils.lib.eachSystem
          [
            "aarch64-linux"
            "x86_64-linux"
          ]
          (
            system:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [ ./. ];
            }
          );
    };
}
