{
  pkgs,
  lib,
  flake,
  inputs,
  lix,
  system,
  ...
}: let
  platform = {
    isLinux = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
    isWayland = pkgs.stdenv.isLinux; # Wayland is Linux-only
  };

  inherit
    (import ./fmt.nix {inherit flake pkgs;})
    formatters
    formatter
    checks
    ;
  dots = import ./dots.nix {inherit pkgs lix lib system formatters platform;};
  media = import ./media.nix {inherit pkgs;};
  devRust = import ./rust.nix {inherit pkgs system inputs platform;};
in {
  devShells = {
    default = dots;
    inherit dots media devRust;
  };
  inherit formatter checks;
}
