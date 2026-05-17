{lix, ...}: let
  inherit (lix.filesystem.importers) importAllPaths;
in {
  imports = importAllPaths ./.;

  # config={};
}
