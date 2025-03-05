{
  description = "QBX Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils-plus = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils-plus,
    }:
    flake-utils-plus.lib.mkFlake {
      inherit self nixpkgs;

      systems = [ "x86_64-linux" ];

      nixosConfigurations = {
        qbx = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./. ];
        };
      };

      devShells = {
        x86_64-linux = {
          default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
            buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
              treefmt2
              nixfmt-rfc-style
              nixd
              shfmt
              shellcheck
              bashInteractive
            ];
          };
        };
      };

      sourceInfo = self.sourceInfo;
    };
}
  