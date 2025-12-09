{
  description = "NixOS configuration for QBX";

  inputs = {
    nixosCore.url = "nixpkgs/nixos-unstable";
    nixosHome = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixosCore";
    };
  };

  outputs =
    inputs@{ self, ... }:
    with inputs;
    let
      args = { inherit self inputs; };
    in
    {
      nixosConfigurations.qbx = nixosCore.lib.nixosSystem {
        specialArgs = args;
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
