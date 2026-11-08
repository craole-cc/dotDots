{lix, ...}: let
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.transformation) filter;
in {
  imports = filter (path: path != ./shared/default.nix) (importAllPaths ./.).value;
}
