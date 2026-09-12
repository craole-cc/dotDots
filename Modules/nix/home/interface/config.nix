{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lib.modules) mkForce;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.styles.cursors) mkCursor;
  inherit (lix.styles.icons) mkIcon;

  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "style";
    mod = "appearance";
  };

  style = user.style or {};
  theme = style.theme or {};
  polarity = theme.polarity or "dark";

  cursorStyle = style.cursors or {};
  cursor = mkCursor {
    inherit pkgs polarity;
    cursor = cursorStyle.${polarity} or null;
    accent = cursorStyle.accent or theme.accent or null;
    flavor = theme.${polarity} or null;
    size = cursorStyle.size or 24;
  };

  iconStyle = style.icons or {};
  icons = mkIcon {
    inherit pkgs polarity;
    icon = iconStyle.${polarity} or null;
  };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = true;
      };
      cursor = mkOption {
        description = "Resolved desktop cursor contract";
        default = cursor;
        type = lix.styles.cursors.types.polarity.home;
        readOnly = true;
      };
      icons = mkOption {
        description = "Resolved desktop icon contract";
        default = icons;
        type = lix.styles.icons.types.icon.home;
        readOnly = true;
      };
    };

    outputs = {
      # DMS scans the XDG user icon directory directly. Expose the resolved
      # package there so it is both selectable and usable by Quickshell.
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

        sessionVariables.QS_ICON_THEME = icons.name;
      };

      qt = mkForce {
        enable = true;
        platformTheme.name = "gtk";
        style.name = "kvantum";
      };
    };
  }
