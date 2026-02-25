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
  minimal = import ./minimal.nix {inherit pkgs;};
in {
  devShells = {
    default = minimal;
    media = media.shell;
    inherit dots minimal;
  };
  inherit formatter checks;
}
