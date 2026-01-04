{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elemAt head length;
  inherit (lib.strings) splitString;

  defaultFonts = {
    pkgs,
    config ? {},
  }: let
    cfg = config.fonts or {};
  in {
    packages =
      cfg.packages or (with pkgs; [
        maple-mono.NF-unhinted
        monaspace
        victor-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ]);

    emoji = cfg.emoji or ["Noto Color Emoji"];
    monospace = cfg.monospace or ["Maple Mono NF" "Victor Mono" "Monaspace Radon"];
    serif = cfg.serif or ["Noto Serif"];
    sansSerif = cfg.sansSerif or ["Noto Sans"];
  };

  #> Parse theme string "catppuccin frappe" -> { family = "catppuccin"; variant = "frappe"; }
  parseTheme = themeStr: let
    parts = splitString " " themeStr;
    family = head parts;
    variant =
      if (length parts) > 1
      then elemAt parts 1
      else null;
  in {inherit family variant;};

  # Theme registry
  themeRegistry = {
    catppuccin = {
      variants = {
        frappe = {
          scheme = "catppuccin-frappe";
          polarity = "dark";
          cursor = {
            name = "catppuccin-frappe-dark-cursors";
            pkg = "frappeDark";
          };
        };
        latte = {
          scheme = "catppuccin-latte";
          polarity = "light";
          cursor = {
            name = "catppuccin-latte-light-cursors";
            pkg = "latteLight";
          };
        };
        macchiato = {
          scheme = "catppuccin-macchiato";
          polarity = "dark";
          cursor = {
            name = "catppuccin-macchiato-dark-cursors";
            pkg = "macchiatoDark";
          };
        };
        mocha = {
          scheme = "catppuccin-mocha";
          polarity = "dark";
          cursor = {
            name = "catppuccin-mocha-dark-cursors";
            pkg = "mochaDark";
          };
        };
      };
      cursorPackage = "catppuccin-cursors";
    };
  };

  resolveTheme = {
    pkgs,
    themeStr,
  }: let
    parsed = parseTheme themeStr;
    themeFamily = themeRegistry.${parsed.family} or null;
    variant =
      if themeFamily != null && parsed.variant != null
      then themeFamily.variants.${parsed.variant} or null
      else null;
  in
    if variant == null
    then null
    else {
      scheme = variant.scheme;
      polarity = variant.polarity;
      cursor = {
        package = pkgs.${themeFamily.cursorPackage}.${variant.cursor.pkg};
        name = variant.cursor.name;
      };
    };

  mkFonts = {
    pkgs,
    host ? {},
    ...
  }: let
    fonts = defaultFonts {
      inherit pkgs;
      config = host.interface or {};
    };
  in {
    fonts = {
      packages = fonts.packages;
      enableDefaultPackages = true;
      fontconfig = {
        enable = true;
        hinting = {
          enable = true;
          style = "slight";
        };
        antialias = true;
        subpixel.rgba = "rgb";
        defaultFonts = {
          inherit (fonts) emoji monospace serif sansSerif;
        };
      };
    };
    environment.sessionVariables = {
      FONT_MONOSPACE = head fonts.monospace;
      FONT_SERIF = head fonts.serif;
      FONT_SANS = head fonts.sansSerif;
      FONT_EMOJI = head fonts.emoji;
    };
  };

  mkStyle = {
    host,
    pkgs,
    ...
  }: let
    style = host.interface.style or {};
    wallpapers = host.paths.wallpapers or null;

    theme =
      style.theme or {
        dark = "catppuccin frappe";
        light = "catppuccin latte";
      };

    current = style.current or "dark";
    currentThemeStr = theme.${current} or theme.dark;
    resolvedTheme = resolveTheme {
      inherit pkgs;
      themeStr = currentThemeStr;
    };

    #> Parse for variant name (for wallpaper lookup)
    parsed = parseTheme currentThemeStr;
    variantName = parsed.variant or "frappe";

    # Wallpaper resolution
    wallpaperPath =
      if (style.wallpaper or null) != null
      then style.wallpaper
      else if wallpapers != null
      then wallpapers + "/${variantName}.png"
      else null;

    # Font configuration
    fonts = defaultFonts {
      inherit pkgs;
      config = host.interface or {};
    };
  in
    optionalAttrs (resolvedTheme != null) {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${resolvedTheme.scheme}.yaml";
        image = wallpaperPath;
        polarity = resolvedTheme.polarity;
        cursor = resolvedTheme.cursor;

        fonts = {
          monospace = {
            package = head fonts.packages;
            name = head fonts.monospace;
          };
          sansSerif = {
            package = pkgs.noto-fonts;
            name = head fonts.sansSerif;
          };
          serif = {
            package = pkgs.noto-fonts;
            name = head fonts.serif;
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = head fonts.emoji;
          };
        };

        opacity = {
          terminal = 0.9;
          popups = 0.95;
        };
      };

      # Export theme variables
      environment.sessionVariables = {
        THEME_CURRENT = current;
        THEME_DARK = theme.dark;
        THEME_LIGHT = theme.light;
        THEME_FAMILY = parsed.family;
        THEME_VARIANT = variantName;
        THEME_POLARITY = resolvedTheme.polarity;
      };
    };

  exports = {inherit mkFonts mkStyle;};
in
  exports // {_rootAliases = exports;}
