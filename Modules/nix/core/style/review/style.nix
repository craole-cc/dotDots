{
  config,
  host,
  lib,
  lix,
  options,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  cfg = config.${top}.${dom}.${mod};

  user = host.users.data.primary or {};
  style = user.interface.style or {};

  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) hasPrefix;
  inherit (lib.modules) mkForce;
  inherit
    (lib.types)
    enum
    int
    nullOr
    str
    ;
  inherit (lix.attrsets.resolution) getPackage;

  themeMap = {
    "Catppuccin Frappé" = {
      scheme = "catppuccin-frappe";
      polarity = "dark";
      cursor = {
        name = "catppuccin-frappe-dark-cursors";
        package = pkgs.catppuccin-cursors.frappeDark;
      };
    };
    "Catppuccin Latte" = {
      scheme = "catppuccin-latte";
      polarity = "light";
      cursor = {
        name = "catppuccin-latte-light-cursors";
        package = pkgs.catppuccin-cursors.latteLight;
      };
    };
    "Catppuccin Macchiato" = {
      scheme = "catppuccin-macchiato";
      polarity = "dark";
      cursor = {
        name = "catppuccin-macchiato-dark-cursors";
        package = pkgs.catppuccin-cursors.macchiatoDark;
      };
    };
    "Catppuccin Mocha" = {
      scheme = "catppuccin-mocha";
      polarity = "dark";
      cursor = {
        name = "catppuccin-mocha-dark-cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
      };
    };
  };

  currentTheme = themeMap.${cfg.theme} or null;
  cursorResolved =
    if cfg.cursor != null
    then {
      name = cfg.cursor;
      package = getPackage {
        inherit pkgs;
        target = cfg.cursor;
        default = pkgs.material-cursors;
      };
    }
    else
      currentTheme.cursor or {
        name = "default";
        package = pkgs.material-cursors;
      };

  wallpaperPath =
    if cfg.wallpaper != null && hasPrefix "/nix/store" cfg.wallpaper
    then /. + cfg.wallpaper
    else if cfg.wallpapersRoot != null && hasPrefix "/nix/store" cfg.wallpapersRoot
    then /. + (cfg.wallpapersRoot + "/${cfg.polarity}.jpg")
    else null;

  hasStylix = options ? stylix;
in {
  options.${top}.${dom}.${mod} = {
    enable =
      mkEnableOption mod
      // {
        default = true;
      };
    theme = mkOption {
      description = "Current theme name";
      default = (style.theme or {}).${style.current or "dark"} or "Catppuccin Frappé";
      defaultText = literalExpression ''(host.users.data.primary.interface.style.theme or {})[host.users.data.primary.interface.style.current or "dark"] or "Catppuccin Frappé"'';
      type = str;
    };
    polarity = mkOption {
      description = "Theme polarity";
      default = style.current or "dark";
      defaultText = literalExpression ''host.users.data.primary.interface.style.current or "dark"'';
      type = enum [
        "dark"
        "light"
      ];
    };
    wallpaper = mkOption {
      description = "Wallpaper path override";
      default = (style.wallpaper or {}).${style.current or "dark"} or null;
      defaultText = literalExpression ''(host.users.data.primary.interface.style.wallpaper or {})[host.users.data.primary.interface.style.current or "dark"] or null'';
      type = nullOr str;
    };
    wallpapersRoot = mkOption {
      description = "Wallpaper directory used when no explicit wallpaper override is set.";
      default = host.paths.wallpapers or null;
      defaultText = literalExpression "host.paths.wallpapers or null";
      type = nullOr str;
    };
    cursor = mkOption {
      description = "Cursor theme override";
      default = (style.cursor or {}).${style.current or "dark"} or null;
      defaultText = literalExpression ''(host.users.data.primary.interface.style.cursor or {})[host.users.data.primary.interface.style.current or "dark"] or null'';
      type = nullOr str;
    };
    cursorSize = mkOption {
      description = "Cursor size in pixels";
      default = (style.cursor or {}).size or 24;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursor.size or 24'';
      type = int;
    };
    autoSwitch =
      mkEnableOption "automatic dark/light switching"
      // {
        default = style.autoSwitch or true;
      };
  };

  config = mkIf (cfg.enable && currentTheme != null) (
    optionalAttrs hasStylix {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentTheme.scheme}.yaml";
        image = wallpaperPath;
        inherit (currentTheme) polarity;

        cursor = {
          inherit (cursorResolved) name package;
          size = cfg.cursorSize;
        };

        icons = let
          set = pkgs.candy-icons;
        in {
          enable = true;
          package = set;
          light = set.name;
          dark = set.name;
        };

        fonts = let
          fontCfg = config.${top}.${dom}.fonts;
        in {
          monospace = {
            package = pkgs.maple-mono.NF-unhinted;
            name = fontCfg.monospace;
          };
          sansSerif = {
            package = pkgs.noto-fonts;
            name = fontCfg.sans;
          };
          serif = {
            package = pkgs.noto-fonts;
            name = fontCfg.serif;
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = fontCfg.emoji;
          };
        };

        opacity = {
          terminal = 0.9;
          popups = 0.95;
        };

        targets.qt.enable = mkForce false;
      };
    }
    // {
      environment.sessionVariables = {
        THEME_CURRENT = cfg.polarity;
        THEME_NAME = cfg.theme;
        WALLPAPER_CURRENT =
          if wallpaperPath != null
          then toString wallpaperPath
          else "";
      };
    }
  );
}
