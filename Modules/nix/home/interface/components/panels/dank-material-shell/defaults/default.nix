{lix}: let
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) fromJSON;
in {
  settings = import ./settings.nix;
  schema = fromJSON (readFile ./settings.schema.json);
  plugins = import ./plugins.nix;
  clipboardSettings = import ./clipboard.nix;
  session = import ./session.nix;
}
