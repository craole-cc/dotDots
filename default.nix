{
  lib ? null,
  flake ? {},
  target ? null,
}:
let
  mkLib = {
    lib ? null,
    flake ? {},
    target ? null,
  }:
    import ./Libraries/nix {
      inherit lib flake target;
      src = ./.;
    };

  resolved = mkLib {inherit lib flake target;};
in
  resolved // {inherit mkLib;}
