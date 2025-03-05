{
  description = "QBX Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      qbx = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./. ];
      };

      devShells.${system}.default = nixpkgs.mkShell {
        buildInputs = with nixpkgs; [
          treefmt2
          nixfmt-rfc-style
          nixd
          shfmt
          shellcheck
          bashInteractive
        ];
      };

      referencedDevShell = self.devShells.x86_64-linux.default;
      sourceInfo = self.sourceInfo;
    };
}
