{config, top, ...}: {
  programs = {
    gh = {
      enable = config.${top}.inputs.applications.utilities.github.enable;
    };
    gh-dash = {
      enable = config.${top}.inputs.applications.utilities.github.enable;
    };
  };
}
