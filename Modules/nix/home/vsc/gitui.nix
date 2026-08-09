{config, top, ...}: {
  programs.gitui = {
    enable = config.${top}.inputs.applications.utilities.gitui.enable;
  };
  ${top}.output.programs.gitui = config.programs.gitui;
}
