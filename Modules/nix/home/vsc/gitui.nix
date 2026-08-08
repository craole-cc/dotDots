{config, top, ...}: {
  programs.gitui = {
    enable = config.${top}.applications.utilities.gitui.enable;
  };
}
