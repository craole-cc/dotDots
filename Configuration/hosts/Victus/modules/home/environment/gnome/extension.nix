{pkgs, ...}: {
  gnome-shell = {
    enable = true;
    # theme = {
    #   name = "Plata-Noir";
    #   package = pkgs.plata-theme;
    # };
    extensions = [
      {
        id = "dash-to-panel@jderose9.github.com";
        package = pkgs.gnomeExtensions.dash-to-panel;
      }
      {
        id = "user-theme@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnome-shell-extensions;
      }
    ];
  };
}
