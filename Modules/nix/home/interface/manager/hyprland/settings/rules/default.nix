{
  lib,
  keyboard,
  apps,
  style,
  mkMerge,
  ...
}: let
  workspaces = import ./workspaces.nix {inherit lib keyboard apps;};
  gaps = import ./gaps.nix {inherit (workspaces) specialWorkspaceNames;};
  window = import ./window.nix {inherit style;};
  layer = import ./layer.nix {inherit lib;};
in
  mkMerge [
    layer
    workspaces
    gaps
    window
  ]
