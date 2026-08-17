{
  config,
  lix,
  top,
  ...
}:
lix.modules.construction.mkConfig {
  payload = {
    programs.tmux =
      {
        enable = config.${top}.resolved.applications.utilities.tmux.enable;
      }
      # // import ./settings.nix
      // import ./plugins.nix;
  };
}
