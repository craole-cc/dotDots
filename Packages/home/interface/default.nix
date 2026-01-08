# {lix, ...}: {imports = lix.filesystem.importers.importAll ./.;}
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkForce;
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
    enable = mkForce true;
    # theme = {
    #   name = "Catppuccin-Mocha-Compact-Pop";
    #   package = pkgs.catppuccin-gtk;
    # };
    iconTheme = mkForce {
      inherit (icons) package name;
    };
    cursorTheme = mkForce {
      inherit (cursor) package name size;
    };
  };

  home.pointerCursor = mkForce {
    gtk.enable = true;
    x11.enable = true;
    inherit (cursor) package name size;
  };

  qt = mkForce {
    enable = true;
    platformTheme = "gtk";
    style.name = "kvantum";
  };
}
