{config, top, ...}: {
  programs.tmux =
    {
      enable = config.${top}.inputs.applications.utilities.tmux.enable;
    }
    # // import ./settings.nix
    // import ./plugins.nix;
}
