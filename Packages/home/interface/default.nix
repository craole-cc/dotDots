# {lix, ...}: {imports = lix.filesystem.importers.importAll ./.;}
{
  pkgs,
  lib,
  user,
  lix,
  ...
}: let
  inherit (lib.modules) mkForce;
  inherit (lib.strings) toLower;
  getPackage = lix.attrsets.resolution.package;
  get = lix.attrsets.resolution.get;

  #~@ Style configuration from user API
  style = user.interface.style or {};
  current = style.current or "dark";

  #~@ Cursor configuration
  cursor = rec {
    # name = toLower (get style.cursor current "material_light_cursors");
    name = "material_light_cursors";
    package = getPackage {
      inherit pkgs;
      target = name;
      default = pkgs.material-cursors;
    };
    size = 32;
  };

  #~@ Icons configuration
  icons = rec {
    # name = toLower (get style.icons current "candy-icons");
    name = "candy-icons";
    package = getPackage {
      inherit pkgs;
      target = name;
      default = pkgs.candy-icons;
    };
  };
in {
  imports = [
    # ./caelestia
    ./darkman
    ./fuzzel
    ./hyprland
    ./niri
    # ./noctula
    # ./quickshell
    # ./plasma
    ./vicinae
  ];

  # catppuccin = {
  #   accent = "teal";
  #   flavor = "latte";
  # };
  gtk = {
    enable = mkForce true;
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
    platformTheme.name = "gtk";
    style.name = "kvantum";
  };
}
