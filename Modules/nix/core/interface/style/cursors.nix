{
  # host,
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
  inherit (lix.styles.cursors.types) core;

  normalizePath = let
    # TODO: Move to filesystem.transformation
    inherit (lix.lists.predicates) elem;
    inherit (lix.lists.predicates) isList;
    inherit (lix.strings.transformation) splitStringBy;
  in
    path:
      if isList path
      then path
      else (splitStringBy (_: sep: elem sep ["." "/"]) false path);

  getCfgWithRef = path: let
    # TODO: Move to attrsets.resolution
    inherit (lix.attrsets.access) attrByPath;
    inherit (lix.lists.access) head;
    inherit (lix.strings.construction) concatStringsSep;
    path' = normalizePath path;
  in {
    ref = concatStringsSep "." path';
    cfg = attrByPath path' {} (head path');
  };

  seed = let
    user = getCfgWithRef [
      "host"
      "users"
      "data"
      "primary"
      "interface"
      "style"
      "cursor"
    ];
    inherit (user) ref cfg;
    name = "catppuccin";
  in {
    inherit ref cfg;
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

  type = either (either str package) core;
  # userPath = "host.users.data.primary.interface.style.cursor";
  example = literalExpression ''
    # as a string (resolved via registry)
    "material"

    # as a package
    pkgs.material-cursors

    # as a resolved attrset
    { name = "material_dark_cursors"; package = pkgs.material-cursors; size = 32; }
  '';

  mkDefaultText = polarity: literalExpression ''${seed.ref}.${polarity} or "${seed.${polarity}}"'';
  mkDescription = polarity: "Cursor theme for the ${polarity} polarity (string, package, or { name, package, size })";
  mkPolarityOption = polarity:
    mkOption {
      description = mkDescription polarity;
      default = seed.${polarity};
      defaultText = mkDefaultText polarity;
      inherit example type;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};
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
      default = seed.variant;
      defaultText = literalExpression ''${seed.ref}.variants or null'';
      type = nullOr (attrsOf str);
    };
  };
}
