{config, top, ...}: {
  programs.direnv = {
    enable = config.${top}.inputs.applications.utilities.direnv.enable;
    silent = true;
    mise.enable = true;
  };
}
