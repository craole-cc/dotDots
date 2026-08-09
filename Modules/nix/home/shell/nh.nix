{config, top, ...}: {
  programs.nh = {
    enable = config.${top}.inputs.applications.utilities.nh.enable;
    clean = {
      enable = true;
      dates = "daily";
    };
  };
  ${top}.output.programs.nh = config.programs.nh;
}
