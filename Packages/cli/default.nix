{
  pkgs,
  lib,
  lix,
  src,
  system,
  ...
}: {
  dots = import ./dots.nix {inherit pkgs lib src system;};
  media = import ./media.nix {inherit pkgs;};
  rust = import ./rust.nix {inherit pkgs;};
}
