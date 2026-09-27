{
  inputs ? lix.inputs or null,
  lib ? import <nixpkgs/lib>,
  lix,
  ...
}: let
  sources = import ./sources.nix {inherit lix lib;};
  overlays = import ./overlays.nix {inherit sources;};
  modules = import ./modules.nix {inherit inputs lix sources;};
in {
  inherit modules overlays;
  inputs = sources;
}
