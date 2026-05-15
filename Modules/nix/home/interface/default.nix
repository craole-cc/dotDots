{
  lix,
  inputs ? {},
  ...
}: let
  imports = lix.filesystem.importers.importAllPaths ./.;
  hasCaelestia = inputs.caelestia ? homeManagerModules;
in {
  imports = builtins.filter (
    path: hasCaelestia || path != ./components/caelestia
  ) imports;
}
