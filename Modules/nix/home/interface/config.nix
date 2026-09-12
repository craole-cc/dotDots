{
  pkgs,
  lib,
  config,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.resolved.${dom};
  inherit (lib.modules) mkForce;
  inherit (lix.attrsets.resolution) package;

  cursor = {
    name = cfg.cursors.name;
    package = package {
      inherit pkgs;
      target = cfg.cursors.name;
      default = pkgs.material-cursors;
    };
    size = cfg.cursors.size;
  };

  icons = {
    name = cfg.icons.name;
    package = package {
      inherit pkgs;
      target = cfg.icons.name;
      default = pkgs.candy-icons;
    };
  };
in {
  _module.args.${dom} = cfg;

  # DMS scans the XDG user icon directory directly. Expose the resolved
  # package there so Candy is both selectable and usable by Quickshell.
  xdg.dataFile."icons/${icons.name}".source =
    "${icons.package}/share/icons/${icons.name}";

  gtk = {
    enable = mkForce true;
    iconTheme = mkForce {inherit (icons) package name;};
    cursorTheme = mkForce {inherit (cursor) package name size;};
    gtk4.theme = null;
  };

  home = {
    pointerCursor = mkForce {
      gtk.enable = true;
      x11.enable = true;
      inherit (cursor) package name size;
    };

    # Quickshell/DMS can resolve themed application icons independently of
    # GTK. Keep it on the same dotDots-resolved icon contract.
    sessionVariables.QS_ICON_THEME = icons.name;
  };

  qt = mkForce {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "kvantum";
  };
}
