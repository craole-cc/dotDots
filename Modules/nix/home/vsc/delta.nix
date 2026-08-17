{
  config,
  lix,
  top,
  ...
}:
lix.modules.construction.mkConfig {
  payload = {
    programs.delta = {
      enable = config.${top}.resolved.applications.utilities.delta.enable;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };
  };
}
