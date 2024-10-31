{
  inputs',
  config,
  pkgs,
  ...
}:
let
  vars = import ./vars.nix;
in
{
  devShells.default = inputs'.devshell.legacyPackages.mkShell {
    inherit (vars) commands env;
    name = "Dots by Nix";
    packages = with pkgs; [
      # inputs'.agenix.packages.default # provide agenix CLI within flake shell
      config.treefmt.build.wrapper # treewide formatter
    ];
  };
}
