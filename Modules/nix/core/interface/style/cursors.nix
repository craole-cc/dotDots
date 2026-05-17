{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "cursors";

  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) either int nullOr package str;
  inherit (lix.style.cursors) types;

  user = host.users.data.primary.interface.style.cursor or {};
  seed = {
    light = "catppuccin";
    dark = "catppuccin";
    size = 24;
  };

  type = either (either str package) types.core;
  userPath = "host.users.data.primary.interface.style.cursor";
  example = literalExpression ''
    # as a string (resolved via registry)
    "material"

    # as a package
    pkgs.material-cursors

    # as a resolved attrset
    { name = "material_dark_cursors"; package = pkgs.material-cursors; size = 32; }
  '';

  mkDefaultText = polarity: literalExpression ''${userPath}.${polarity} or "${seed.${polarity}}"'';
  mkDescription = polarity: "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
  mkPolarityOption = polarity:
    mkOption {
      description = mkDescription polarity;
      default = user.${polarity} or seed.${polarity};
      defaultText = mkDefaultText polarity;
      inherit example type;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};

    light = mkPolarityOption "light";
    dark = mkPolarityOption "dark";

    size = mkOption {
      description = "Global cursor size in pixels, used when not set per polarity";
      default = user.size or seed.size;
      defaultText = literalExpression ''${userPath}.size or 24'';
      type = int;
    };

    accent = mkOption {
      description = "Catppuccin accent color for cursor themes that support it";
      default = user.accent or null;
      defaultText = literalExpression ''${userPath}.accent or null'';
      type = nullOr str;
    };

    variant = mkOption {
      description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it";
      default = user.variant or null;
      defaultText = literalExpression ''${userPath}.variant or null'';
      type = nullOr (lib.types.attrsOf str);
    };
  };
}
