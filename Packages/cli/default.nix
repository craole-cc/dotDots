{
  pkgs,
  lib,
  lix,
  src,
  system,
  ...
}: let
  dots = import ./dots.nix {inherit pkgs lix lib src system;};
  media = import ./media.nix {inherit pkgs;};
  rust = import ./rust.nix {inherit pkgs;};
in {
  default = dots;
  inherit dots media rust;
}
