{osConfig, ...}: {
  services.dunst = {
    settings.global.icon_path = "${osConfig.dots.paths.qbx.conf}/dunst/icons";
    iconTheme = {
      name = "Catppuccin-Mocha-Dark";
      package = pkgs.catppuccinIcons;
      size = "32x32";
    };
  };
}
