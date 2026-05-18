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
  inherit (lix.styles.types.cursors) core;
  inherit (lix.attrsets.resolution) withPath;

  seed = let
    user = withPath {
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
    inherit (user) path value;
    name = "catppuccin";
  in {
    inherit path;
    light = value.light or name;
    dark = value.dark or name;
    size = value.size or 32;
    accent = value.accent or "teal";
    variants =
      value.variants or {
        light = "latte";
        dark = "frappe";
      };
  };

  # TODO: Move to styles.types.cursors.polarity.core
  mkPolarityOption = polarity:
    mkOption {
      description = "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
      default = seed.${polarity};
      defaultText = literalExpression ''${seed.path}.${polarity} or "${seed.${polarity}}"'';
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
    # _test = mkOption {
    #   description = "test stuff";
    #   default = seed;
    #   defaultText = literalExpression ''${seed.path}.size or 24'';
    # };

    enable = mkEnableOption mod // {default = true;};
    light = mkPolarityOption "light";
    dark = mkPolarityOption "dark";

    size = mkOption {
      description = "Global cursor size in pixels, used when not overridden per polarity";
      default = seed.size;
      defaultText = literalExpression ''${seed.path}.size or 24'';
      type = int;
    };

    accent = mkOption {
      description = "Catppuccin accent color for cursor themes that support it";
      default = seed.accent;
      defaultText = literalExpression ''${seed.path}.accent or null'';
      type = nullOr str;
    };

    variants = mkOption {
      description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it";
      default = seed.variants;
      defaultText = literalExpression ''${seed.path}.variants or null'';
      type = nullOr (attrsOf str);
    };
  };
}
