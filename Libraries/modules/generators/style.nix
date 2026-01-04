{
  _,
  lib,
  ...
}: let
  inherit (lib.lists) head;

  mkFonts = {
    pkgs,
    packages ? {},
    emoji ? [],
    monospace ? [],
    serif ? [],
    sansSerif ? [],
    ...
  }: let
    res = {
      packages =
        if packages != {}
        then packages
        else
          with pkgs; [
            #~@ Monospace
            # maple-mono.NF
            maple-mono.NF-unhinted
            monaspace
            victor-mono

            #~@ System
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
          ];
      emoji =
        if emoji != []
        then emoji
        else ["Noto Color Emoji"];
      monospace =
        if monospace != []
        then monospace
        else ["Maple Mono NF" "Victor Mono" "Monaspace Radon"];
      serif =
        if serif != []
        then serif
        else ["Noto Serif"];
      sansSerif =
        if sansSerif != []
        then sansSerif
        else ["Noto Sans"];
    };
  in {
    fonts = {
      inherit (res) packages;
      enableDefaultPackages = true;
      fontconfig = {
        enable = true;
        hinting = {
          enable = true; # TODO: This should depend on the host specs
          style = "slight";
        };
        antialias = true;
        subpixel.rgba = "rgb";
        defaultFonts = {inherit (res) emoji monospace serif sansSerif;};
      };
    };
    environment.sessionVariables = {
      FONT_MONOSPACE = head res.monospace;
      FONT_SERIF = head res.serif;
      FONT_SANS = head res.sansSerif;
      FONT_EMOJI = head res.emoji;
    };
  };

  mkStyle = {
    host,
    pkgs,
    ...
  }: let
    style = host.interface.style or {};
    theme = style.theme or "catppuccin";
    variant = style.variant or "frappe";
    polarity = style.polarity or "dark";
    wallpaper = style.wallpaper or null;
    wallpapers = host.paths.wallpapers or null;

    # Catppuccin theme mappings
    catppuccinSchemes = {
      frappe = {
        scheme = "catppuccin-frappe";
        polarity = "dark";
        cursor = {
          package = pkgs.catppuccin-cursors.frappeDark;
          name = "catppuccin-frappe-dark-cursors";
        };
      };
      latte = {
        scheme = "catppuccin-latte";
        polarity = "light";
        cursor = {
          package = pkgs.catppuccin-cursors.latteLight;
          name = "catppuccin-latte-light-cursors";
        };
      };
      macchiato = {
        scheme = "catppuccin-macchiato";
        polarity = "dark";
        cursor = {
          package = pkgs.catppuccin-cursors.macchiatoDark;
          name = "catppuccin-macchiato-dark-cursors";
        };
      };
      mocha = {
        scheme = "catppuccin-mocha";
        polarity = "dark";
        cursor = {
          package = pkgs.catppuccin-cursors.mochaDark;
          name = "catppuccin-mocha-dark-cursors";
        };
      };
    };

    selectedTheme = catppuccinSchemes.${variant} or catppuccinSchemes.frappe;

    # Determine wallpaper path
    wallpaperPath =
      if wallpaper != null
      then wallpaper
      else if wallpapers != null
      then "${wallpapers}/${variant}.png" # Assumes you name wallpapers frappe.png, latte.png, etc.
      else "${pkgs.base16-schemes}/share/wallpapers/${selectedTheme.scheme}.png";
  in {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${selectedTheme.scheme}.yaml";
      image = wallpaperPath;
      polarity = polarity;

      cursor = selectedTheme.cursor;

      fonts = {
        monospace = {
          package = pkgs.maple-mono.NF-unhinted;
          name = "Maple Mono NF";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      opacity = {
        terminal = 0.9;
        popups = 0.95;
      };
    };

    # Export theme info as environment variables for scripts
    environment.sessionVariables = {
      THEME_NAME = theme;
      THEME_VARIANT = variant;
      THEME_POLARITY = polarity;
    };
  };

  exports = {inherit mkFonts mkStyle;};
in
  exports // {_rootAliases = exports;}
