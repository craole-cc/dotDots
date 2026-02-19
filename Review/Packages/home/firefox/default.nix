{osConfig, ...}: {
  programs.firefox = {
    enableGnomeExtensions = osConfig.services.gnome.gnome-browser-connector.enable;
  };
}
