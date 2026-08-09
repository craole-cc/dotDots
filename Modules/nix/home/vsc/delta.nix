{config, top, ...}: {
  programs.delta = {
    enable = config.${top}.inputs.applications.utilities.delta.enable;
    enableGitIntegration = true;
    enableJujutsuIntegration = true;
  };
  ${top}.output.programs.delta = config.programs.delta;
}
