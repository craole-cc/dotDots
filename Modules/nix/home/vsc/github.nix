{
  config,
  lix,
  top,
  ...
}:
lix.modules.construction.mkConfig {
  payload = {
    programs = {
      gh = {
        enable = config.${top}.resolved.applications.utilities.github.enable;
      };
      gh-dash = {
        enable = config.${top}.resolved.applications.utilities.github.enable;
      };
    };
  };
}
