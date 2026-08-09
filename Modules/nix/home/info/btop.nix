{config, top, ...}: {
  programs.btop = {
    enable = config.${top}.inputs.applications.utilities.btop.enable;
  };
  ${top}.output.programs.btop = config.programs.btop;
}
