{
  config,
  host,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "fonts";
  cfg = config.${top}.${dom}.${mod};

  user = host.users.data.primary or {};
  userFonts = user.interface.style.fonts or {};

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf package str;

  defaultPackages = with pkgs; [
    maple-mono.NF-unhinted
    material-icons
    material-symbols
    monaspace
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    victor-mono
  ];
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    packages = mkOption {
      description = "Font packages to install";
      default = defaultPackages;
      type = listOf package;
    };
    monospace = mkOption {
      description = "Monospace font";
      default = userFonts.monospace or "Maple Mono NF";
      type = str;
    };
    sans = mkOption {
      description = "Sans-serif font";
      default = userFonts.sans or "Monaspace Radon Frozen";
      type = str;
    };
    serif = mkOption {
      description = "Serif font";
      default = userFonts.serif or "Noto Serif";
      type = str;
    };
    emoji = mkOption {
      description = "Emoji font";
      default = userFonts.emoji or "Noto Color Emoji";
      type = str;
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = cfg.packages;
      enableDefaultPackages = true;
      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          style = "slight";
        };
        subpixel.rgba = "rgb";
        defaultFonts = {
          monospace = [cfg.monospace];
          sansSerif = [cfg.sans];
          serif = [cfg.serif];
          emoji = [cfg.emoji];
        };
      };
    };

    environment.sessionVariables = {
      FONT_MONOSPACE = cfg.monospace;
      FONT_SANS = cfg.sans;
      FONT_SERIF = cfg.serif;
      FONT_EMOJI = cfg.emoji;
    };
  };
}
