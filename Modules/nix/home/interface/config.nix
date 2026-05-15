{
  pkgs,
  lib,
  user,
  config,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.${dom};
  inherit (lib.modules) mkForce;
  # inherit (lib.strings) toLower;
  getPackage = lix.attrsets.resolution.package;
  # get = lix.attrsets.resolution.get;

  #~@ Style configuration from user API
  # style = user.interface.style or {};
  # current = style.current or "dark";

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
  # _module.args = {inherit cursor icons;};
  _module.args.${dom} = cfg;

  gtk = {
    enable = mkForce true;
    iconTheme = mkForce {inherit (icons) package name;};
    cursorTheme = mkForce {inherit (cursor) package name size;};
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 0; # ← Force light
    gtk4 = {
      theme = null;
      # theme=config.gtk.theme;
      extraConfig.gtk-application-prefer-dark-theme = 0; # ← Force light
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

  stylix = {
    # enable = false;
    # polarity = "light";
    targets = {
      qt.enable = mkForce false;
      foot = {
        enable = true;
        colors.enable = false; # ? Stylix is using the deprecated [colors]
        opacity.enable = false;
        # fonts.enable = false;
      };
      zen-browser = {
        profileNames = [user.name];
      };
    };
  };
}
