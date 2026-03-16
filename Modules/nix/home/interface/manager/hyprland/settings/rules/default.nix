{
  lib,
  keyboard,
  apps,
  mkMerge,
  ...
}:
mkMerge [
  (import ./layer.nix {inherit lib;})
  (import ./window.nix)
  (import ./gaps.nix)
  (import ./workspaces.nix {inherit lib keyboard apps;})
]
