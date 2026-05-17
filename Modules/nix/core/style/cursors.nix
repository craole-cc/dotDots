{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "style";
  mod = "cursors";

  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) attrsOf either int nullOr package str;
  inherit (lix.styles.cursors.types) core;
  inherit (lix.attrsets.resolution) withRef;

  seed = let
    user = withRef {
      base = {
        name = "host";
        value = host;
      };
      path = [
        "users"
        "data"
        "primary"
        "style"
        "cursors"
      ];
    };
    inherit (user) ref cfg;
    name = "catppuccin";
  in {
    inherit user ref cfg;
    light = cfg.light or name;
    dark = cfg.dark or name;
    size = cfg.size or 32;
    accent = cfg.accent or "teal";
    variants =
      cfg.variants or {
        light = "latte";
        dark = "frappe";
      };
  };

  # TODO: Move to styles.types.cursors.polarity.core
  mkPolarityOption = polarity:
    mkOption {
      description = "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
      default = seed.${polarity};
      defaultText = literalExpression ''${seed.ref}.${polarity} or "${seed.${polarity}}"'';
      example = literalExpression ''
        # as a string (resolved via registry)
        "material"

        # as a package
        pkgs.material-cursors

        # as a resolved attrset
        { name = "material_dark_cursors"; package = pkgs.material-cursors; size = 32; }
      '';
      type = either (either str package) core;
    };
in {
  options.${top}.${dom}.${mod} = {
    _test = mkOption {
      description = "test stuff";
      default = seed;
      # defaultText = literalExpression ''${seed.ref}.size or 24'';
      # type = lib.types.raw;
    };

    enable = mkEnableOption mod // {default = true;};
    light = mkPolarityOption "light";
    dark = mkPolarityOption "dark";

    size = mkOption {
      description = "Global cursor size in pixels, used when not overridden per polarity";
      default = seed.size;
      defaultText = literalExpression ''${seed.ref}.size or 24'';
      type = int;
    };

    accent = mkOption {
      description = "Catppuccin accent color for cursor themes that support it";
      default = seed.accent;
      defaultText = literalExpression ''${seed.ref}.accent or null'';
      type = nullOr str;
    };

    variants = mkOption {
      description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it";
      default = seed.variants;
      defaultText = literalExpression ''${seed.ref}.variants or null'';
      type = nullOr (attrsOf str);
    };
  };
}
