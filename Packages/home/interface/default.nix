# {lix, ...}: {imports = lix.filesystem.importers.importAll ./.;}
{pkgs, ...}: let
  cursor = {
    package = pkgs.material-cursors;
    name = "material_light_cursors";
    size = 32;
  };
  icons = {
    package = pkgs.candy-icons;
    name = "candy-icons";
  };
in {
  imports = [
    ./caelestia
    ./darkman
    ./fuzzel
    ./hyprland
    ./niri
    # ./noctula
    # ./quickshell
    ./plasma
    ./vicinae
  ];

  gtk = {
    enable = true;
    # theme = {
    #   name = "Catppuccin-Mocha-Compact-Pop";
    #   package = pkgs.catppuccin-gtk;
    # };
    iconTheme = {
      inherit (icons) package name;
    };
    cursorTheme = {
      inherit (cursor) package name size;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    inherit (cursor) package name size;
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };
}
