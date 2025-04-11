{ pkgs, paths, ... }:
let
  cmd = import ./cmd.nix;
  env = import ./env.nix { inherit paths; };
  fmt = import ./fmt.nix { inherit pkgs; };
  pkg = import ./pkg.nix { inherit pkgs; };
in
pkgs.inputs.developmentShell.mkShell {
  name = "dotDots";
  inherit env;
  packages = pkg ++ fmt;
  commands = cmd;
}
