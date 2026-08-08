{config, top, ...}: {
  programs = {
    gh = {
      enable = config.${top}.applications.utilities.github.enable;
    };
    gh-dash = {
      enable = config.${top}.applications.utilities.github.enable;
    };
  };
}
