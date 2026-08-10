{
  misc = {
    #? disable auto polling for config file changes
    disable_autoreload = true;

    force_default_wallpaper = 0;
  };

  experimental = {
    #? Variable refresh rate (effective depending on hardware)
    #? Moved from misc.vrr (removed in Hyprland 0.45+)
    vrr = 1;
  };
}
