{
  pkgs,
  lib,
  flake,
  inputs,
  lix,
  system,
  ...
}: let
  inherit
    (import ./fmt.nix {inherit flake pkgs;})
    formatters
    formatter
    checks
    ;
  dots = import ./dots.nix {inherit pkgs lix lib system formatters;};
  media = import ./media.nix {inherit pkgs;};
  devRust = import ./rust.nix {inherit pkgs system inputs;};
in {
  devShells = {
    default = dots;
    inherit dots media devRust;
  };
  inherit formatter checks;
}
