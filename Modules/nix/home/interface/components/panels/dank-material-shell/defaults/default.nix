{lix}: let
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) fromJSON;
in {
  settings =
    (import ./settings.nix)
    // {clipboard = import ./clipboard.nix;};
  schema = fromJSON (readFile ./settings.schema.json);
  plugins = import ./plugins.nix;
  session = import ./session.nix;
}
