{lix, ...}: let
  inherit (lix.filesystem.traversal) importAllPaths;
in {
  imports = (importAllPaths ./.).value;

  # config={};
}
