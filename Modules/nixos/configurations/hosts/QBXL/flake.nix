{
  description = "QBB-WSL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager?ref=master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL?ref=main";
  };

  outputs =
    {
      # self,
      nixpkgs,
      nixos-wsl,
      ...
    }:
    {
      nixosConfigurations.QBXL = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          ./core
          ./home
          ./options
        ];
      };
    };
}
