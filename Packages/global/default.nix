{
  pkgs,
  lib,
  flake,
  lix,
  system,
  ...
}: let
  inherit (import ./fmt.nix {inherit pkgs flake;}) formatters formatter checks;
  dots = import ./dots.nix {inherit pkgs lix lib system formatters;};
  media = import ./media.nix {inherit pkgs;};
  rust = import ./rust.nix {inherit pkgs;};
in {
  devShells = {
    default = dots;
    inherit dots media rust;
  };
  inherit formatter checks;
}
