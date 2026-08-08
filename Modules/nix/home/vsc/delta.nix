{config, top, ...}: {
  programs.delta = {
    enable = config.${top}.applications.utilities.delta.enable;
    enableGitIntegration = true;
    enableJujutsuIntegration = true;
  };
}
