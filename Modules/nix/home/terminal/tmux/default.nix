{config, top, ...}: {
  programs.tmux =
    {
      enable = config.${top}.applications.utilities.tmux.enable;
    }
    # // import ./settings.nix
    // import ./plugins.nix;
}
