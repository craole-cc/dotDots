{osConfig, ...}: {
  imports = [];
  programs.eww = {
    enable = true;
    # configDir = osConfig.dots.paths.conf.eww;
    configDir = osConfig.dots.paths.qbx.conf.eww;
    # configDir = toString (osConfig.dots.paths.conf + "/eww");
  };
}
