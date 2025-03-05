{
  description = "QBX Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      qbx = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./. ];
      };
    };
}
