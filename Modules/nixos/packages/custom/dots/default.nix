{ pkgs, paths, ... }:
pkgs.inputs.developmentShell.mkShell {
  name = "dotDots";
  env = import ./env.nix { inherit paths; };
  packages = [
    (import ./pkg.nix { inherit pkgs; })
    (import ./fmt.nix { inherit pkgs; })
  ];
  commands = import ./cmd.nix;
}
