{
  config,
  host,
  lib,
  lix,
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

  inherit (lib.modules) mkIf mkForce;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) hasPrefix;
  inherit (lib.types) bool enum int nullOr str;
  getPackage = lix.attrsets.resolution.package;

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

  #~@ Cursor resolution — user override takes precedence over theme default
  cursorName = style.cursor.${style.current or "dark"} or null;
  cursorResolved =
    if cursorName != null
    then {
      name = cursorName;
      package = getPackage {
        inherit pkgs;
        target = cursorName;
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
    else if wallpapers != null && hasPrefix "/nix/store" wallpapers
    then /. + (wallpapers + "/${cfg.polarity}.jpg")
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
    cursorSize = mkOption {
      description = "Cursor size in pixels";
      default = style.cursor.size or 24;
      type = int;
    };
    autoSwitch = mkOption {
      description = "Enable automatic dark/light switching";
      default = style.autoSwitch or false;
      type = bool;
    };
  };

  config = mkIf (cfg.enable && currentTheme != null) {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${currentTheme.scheme}.yaml";
      image = wallpaperPath;
      polarity = currentTheme.polarity;

      cursor = {
        inherit (cursorResolved) name package;
        size = cfg.cursorSize;
      };

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

      targets = {
        qt.enable = mkForce false;
      };
    };

    environment.sessionVariables = {
      THEME_CURRENT = cfg.polarity;
      THEME_NAME = cfg.theme;
      WALLPAPER_CURRENT = lib.optionalString (wallpaperPath != null) (toString wallpaperPath);
    };
  };
}
