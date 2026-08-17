{
  config,
  lix,
  top,
  ...
}:
lix.modules.construction.mkConfig {
  payload = {
    programs.gitui = {
      enable = config.${top}.resolved.applications.utilities.gitui.enable;
    };
  };
}
