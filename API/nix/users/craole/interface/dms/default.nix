#TODO: All this we have defined here should be moved to the dms module as default values. Remember this is just API, not the actual implementation of the module. The actual implementation should be in the dms module.
{
  dms = {
    settings = import ./settings.nix;
    schema = builtins.fromJSON (builtins.readFile ./settings.schema.json);
    plugins = import ./plugins.nix;
    clipboardSettings = import ./clipboard.nix;
    session = import ./session.nix;
  };
}
