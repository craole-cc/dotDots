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
  inherit (lib.types) attrsOf either int nullOr package str;
  inherit (lix.styles.types) cursors;

  user = host.users.data.primary.interface.style.cursor or {};
  seed = {
    light   = "catppuccin";
    dark    = "catppuccin";
    size    = 24;
    accent  = null;
    variant = null;
  };

  type     = either (either str package) cursors.core;
  userPath = "host.users.data.primary.interface.style.cursor";
  example  = literalExpression ''
    # as a string (resolved via registry)
    "material"

    # as a package
    pkgs.material-cursors

    # as a resolved attrset
    { name = "material_dark_cursors"; package = pkgs.material-cursors; size = 32; }
  '';

  mkDefaultText    = polarity: literalExpression ''${userPath}.${polarity} or "${seed.${polarity}}"'';
  mkDescription    = polarity: "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
  mkPolarityOption = polarity: mkOption {
    description = mkDescription polarity;
    default     = user.${polarity} or seed.${polarity};
    defaultText = mkDefaultText polarity;
    inherit example type;
  };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};
    light   = mkPolarityOption "light";
    dark    = mkPolarityOption "dark";

    size = mkOption {
      description = "Global cursor size in pixels, used when not overridden per polarity";
      default     = user.size or seed.size;
      defaultText = literalExpression ''${userPath}.size or 24'';
      type        = int;
    };

    accent = mkOption {
      description = "Catppuccin accent colour for cursor themes that support it";
      default     = user.accent or seed.accent;
      defaultText = literalExpression ''${userPath}.accent or null'';
      type        = nullOr str;
    };

    variants = mkOption {
      description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it";
      default     = user.variants or seed.variant;
      defaultText = literalExpression ''${userPath}.variants or null'';
      type        = nullOr (attrsOf str);
    };
  };
}
