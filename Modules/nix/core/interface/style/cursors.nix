{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    # sub = "style";
    mod = "cursors";
  };

  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf either nullOr;
  inherit (lix.types.primitives) int package str;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.styles.cursors.types.polarity) core;
  inherit (lix.attrsets.resolution) withPath;

  registry = let
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

  # TODO: Move to styles.cursors.types.polarity.core
  mkPolarityOption = value: let
    path = "${registry.path}.${value}";
    polarity = registry.${value};
  in
    mkOption {
      description = "Cursor theme for the ${value} polarity (string, package, or { name, package, size })";
      default = polarity;
      defaultText = literalExpression ''${path} or "${polarity}"'';
      example = literalExpression ''
        # as a string (resolved via registry)
        "material"

        # as a package
        pkgs.material-cursors

        # as a resolved attrset
        {
          name = "material_dark_cursors";
          package = pkgs.material-cursors;
          size = 32;
        }
      '';
      type = either (either str package) core;
    };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Whether to enable cursor theming.";
        condition = true;
      };

      light = mkPolarityOption "light";
      dark = mkPolarityOption "dark";

      size = with registry;
        mkOption {
          description = "Global cursor size in pixels, used when not overridden per polarity.";
          default = size;
          defaultText = literalExpression "${path}.size or 24";
          type = int;
        };

      accent = with registry;
        mkOption {
          description = "Catppuccin accent color for cursor themes that support it.";
          default = accent;
          defaultText = literalExpression "${path}.accent or null";
          type = nullOr str;
        };

      variants = with registry;
        mkOption {
          description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it.";
          default = variants;
          defaultText = literalExpression "${path}.variants or null";
          type = nullOr (attrsOf str);
        };
    };

    outputs = {};
  }
# {
#   host,
#   lib,
#   lix,
#   top,
#   ...
# }: let
#   dom = "style";
#   mod = "cursors";
#   inherit (lib.options) literalExpression mkEnableOption mkOption;
#   inherit
#     (lib.types)
#     attrsOf
#     either
#     int
#     nullOr
#     package
#     str
#     ;
#   inherit (lix.styles.cursors.types.polarity) core;
#   inherit (lix.attrsets.resolution) withPath;
#   seed = let
#     user = withPath {
#       base = {
#         name = "host";
#         value = host;
#       };
#       path = [
#         "users"
#         "data"
#         "primary"
#         "style"
#         "cursors"
#       ];
#     };
#     inherit (user) path value;
#     name = "catppuccin";
#   in {
#     inherit path;
#     light = value.light or name;
#     dark = value.dark or name;
#     size = value.size or 32;
#     accent = value.accent or "teal";
#     variants =
#       value.variants or {
#         light = "latte";
#         dark = "frappe";
#       };
#   };
#   # TODO: Move to styles.cursors.types.polarity.core
#   mkPolarityOption = polarity:
#     mkOption {
#       description = "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
#       default = seed.${polarity};
#       defaultText = literalExpression ''${seed.path}.${polarity} or "${seed.${polarity}}"'';
#       example = literalExpression ''
#         # as a string (resolved via registry)
#         "material"
#         # as a package
#         pkgs.material-cursors
#         # as a resolved attrset
#         { name = "material_dark_cursors"; package = pkgs.material-cursors; size = 32; }
#       '';
#       type = either (either str package) core;
#     };
# in {
#   options.${top}.resolved.${dom}.${mod} = {
#     # _test = mkOption {
#     #   description = "test stuff";
#     #   default = seed;
#     #   defaultText = literalExpression ''${seed.path}.size or 24'';
#     # };
#     enable =
#       mkEnableOption mod
#       // {
#         default = true;
#       };
#     light = mkPolarityOption "light";
#     dark = mkPolarityOption "dark";
#     size = mkOption {
#       description = "Global cursor size in pixels, used when not overridden per polarity";
#       default = seed.size;
#       defaultText = literalExpression "${seed.path}.size or 24";
#       type = int;
#     };
#     accent = mkOption {
#       description = "Catppuccin accent color for cursor themes that support it";
#       default = seed.accent;
#       defaultText = literalExpression "${seed.path}.accent or null";
#       type = nullOr str;
#     };
#     variants = mkOption {
#       description = "Catppuccin variant per polarity ({ light, dark }) for cursor themes that support it";
#       default = seed.variants;
#       defaultText = literalExpression "${seed.path}.variants or null";
#       type = nullOr (attrsOf str);
#     };
#   };
# }

