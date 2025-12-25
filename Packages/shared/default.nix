{
  pkgs,
  lib,
  flake,
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
  media = import ./media.nix {inherit pkgs;};
  dots = import ./dots.nix {
    inherit pkgs lix lib system;
    mediaPackages = media.packages;
    fmtPackages = formatters;
  };
in {
  devShells = {
    default = dots;
    media = media.shell;
    inherit dots;
  };
  inherit formatter checks;
}
