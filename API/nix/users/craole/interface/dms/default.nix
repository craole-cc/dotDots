{
  dms = {
    settings = import ./settings.nix;
    schema = builtins.fromJSON (builtins.readFile ./settings.schema.json);
    plugins = import ./plugins.nix;
    clipboardSettings = import ./clipboard.nix;
    session = import ./session.nix;
  };
}
