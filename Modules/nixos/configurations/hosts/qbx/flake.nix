{
  description = "Development environment for qbx host with treefmt2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils-plus,
    }:
    flake-utils-plus.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        formatConfig = import ./custom/fmt.nix { inherit pkgs; };
      in
      {
        inherit (formatConfig) formatter;

        devShells.default = pkgs.mkShell {
          name = "qbx-dev-shell";
          buildInputs = formatConfig.devInputs;

          shellHook = ''
            echo "🚀 Welcome to the qbx development environment!"
            echo "Formatting tools are ready with treefmt2"
            echo "Use 'treefmt' to format all files in the project"
          '';
        };
      }
    );
}
