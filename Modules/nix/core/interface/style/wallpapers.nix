{
  config,
  host,
  tree,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "wallpapers";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything nullOr path str;
  inherit (lix.modules.core.style) resolveWallpapers;

  user =
    recursiveUpdate {
      interface.style.wallpapers = {
        dots = host.dots or "$DOTS";
        pics = "$HOME/Pictures";
        light = {};
        dark = {};
      };
    }
    (host.users.data.primary or {});

  seed = let
    w = user.interface.style.wallpapers;
  in
    resolveWallpapers {
      inherit (lix) tree;
      inherit (w) dots pics light dark;
    }
    // {
      inherit (w) dots pics light dark;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    dots = mkOption {
      description = "Path prefix for dotfiles wallpaper assets (used to build file/dirs)";
      default = seed.dots;
      defaultText = literalExpression ''host.users.data.primary.interface.style.wallpapers.dots or "$DOTS"'';
      type = str;
    };

    pics = mkOption {
      description = "User pictures directory prefix (used to build wallpaper search dirs)";
      default = seed.pics;
      defaultText = literalExpression ''host.users.data.primary.interface.style.wallpapers.pics or "$HOME/Pictures"'';
      type = str;
    };

    light = mkOption {
      description = "Overrides for the light-polarity wallpaper set (image, file, dirs)";
      default = seed.light;
      defaultText = literalExpression ''host.users.data.primary.interface.style.wallpapers.light or {}'';
      type = attrsOf anything;
    };

    dark = mkOption {
      description = "Overrides for the dark-polarity wallpaper set (image, file, dirs)";
      default = seed.dark;
      defaultText = literalExpression ''host.users.data.primary.interface.style.wallpapers.dark or {}'';
      type = attrsOf anything;
    };

    resolved = mkOption {
      description = "Resolved wallpaper attrset ({ light, dark } each with image, file, dirs), derived from active options";
      default = resolveWallpapers {
        inherit (lix) tree;
        dots = cfg.dots;
        pics = cfg.pics;
        light = cfg.light;
        dark = cfg.dark;
      };
      defaultText = literalExpression "resolveWallpapers { inherit tree dots pics light dark; }";
      type = attrsOf anything;
      readOnly = true;
    };
  };
}
