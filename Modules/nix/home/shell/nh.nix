{config, top, ...}: {
  programs.nh = {
    enable = config.${top}.applications.utilities.nh.enable;
    clean = {
      enable = true;
      dates = "daily";
    };
  };
}
