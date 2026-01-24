{lix, ...}: let
  inherit (lix.filesystem.importers) importAll;
in {
  imports = importAll ./.;
  _module.args = {inherit importAll;};
}
