{
  pkgs,
  lib,
  lix,
  system,
  formatters ? [],
  ...
}: let
  dots = import ./dots.nix {
    inherit pkgs lix lib system;
    formatters =
      if formatters != []
      then formatters
      else (import ./fmt.nix) formatters;
  };
  media = import ./media.nix {inherit pkgs;};
  rust = import ./rust.nix {inherit pkgs;};
in {
  default = dots;
  inherit dots media rust;
}
