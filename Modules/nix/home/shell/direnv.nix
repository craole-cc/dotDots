{config, top, ...}: {
  programs.direnv = {
    enable = config.${top}.applications.utilities.direnv.enable;
    silent = true;
    mise.enable = true;
  };
}
