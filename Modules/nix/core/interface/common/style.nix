# interface/style/style.nix
{
  config,
  host,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  cfg = config.${top}.${dom}.${mod};

  user = host.users.data.primary or {};
  style = user.interface.style or {};
  wallpapers = host.paths.wallpapers or null;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum nullOr str;

  themeMap = {
    "Catppuccin Frappé" = {
      scheme = "catppuccin-frappe";
      polarity = "dark";
      cursor = {
        name = "catppuccin-frappe-dark-cursors";
        pkg = pkgs.catppuccin-cursors.frappeDark;
        size = 24;
      };
    };
    "Catppuccin Latte" = {
      scheme = "catppuccin-latte";
      polarity = "light";
      cursor = {
        name = "catppuccin-latte-light-cursors";
        pkg = pkgs.catppuccin-cursors.latteLight;
        size = 24;
      };
    };
    "Catppuccin Macchiato" = {
      scheme = "catppuccin-macchiato";
      polarity = "dark";
      cursor = {
        name = "catppuccin-macchiato-dark-cursors";
        pkg = pkgs.catppuccin-cursors.macchiatoDark;
        size = 24;
      };
    };
    "Catppuccin Mocha" = {
      scheme = "catppuccin-mocha";
      polarity = "dark";
      cursor = {
        name = "catppuccin-mocha-dark-cursors";
        pkg = pkgs.catppuccin-cursors.mochaDark;
        size = 24;
      };
    };
  };

  currentTheme = themeMap.${cfg.theme} or null;

  wallpaperPath =
    if cfg.wallpaper != null
    then cfg.wallpaper
    else if wallpapers != null
    then wallpapers + "/${cfg.polarity}.jpg"
    else null;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = currentTheme != null;};
    theme = mkOption {
      description = "Current theme name";
      default = style.theme.${style.current or "dark"} or "Catppuccin Frappé";
      type = str;
    };
    polarity = mkOption {
      description = "Theme polarity";
      default = style.current or "dark";
      type = enum ["dark" "light"];
    };
    wallpaper = mkOption {
      description = "Wallpaper path override";
      default = style.wallpaper.${style.current or "dark"} or null;
      type = nullOr str;
    };
    autoSwitch = mkOption {
      description = "Enable automatic dark/light switching";
      default = style.autoSwitch or false;
      type = lib.types.bool;
    };
  };

  config = mkIf (cfg.enable && currentTheme != null) {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentTheme.scheme}.yaml";
      image = wallpaperPath;
      polarity = currentTheme.polarity;
      # cursor = currentTheme.cursor;

      fonts = let
        fontCfg = config.${top}.interface.fonts;
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

      targets.qt.enable = lib.mkForce false;
    };

    environment.sessionVariables = {
      THEME_CURRENT = cfg.polarity;
      THEME_NAME = cfg.theme;
      WALLPAPER_CURRENT = lib.optionalString (wallpaperPath != null) wallpaperPath;
    };
  };
}
