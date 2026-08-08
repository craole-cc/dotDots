{config, top, ...}: {
  programs.btop = {
    enable = config.${top}.applications.utilities.btop.enable;
  };
}
