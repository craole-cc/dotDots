{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "cursors";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything int nullOr str;
  inherit (lix.modules.core.style) resolveCursors;

  user =
    recursiveUpdate {
      interface.style.cursors = {
        size = 24;
        accent = null;
        variant = null;
        light = {};
        dark = {};
      };
    }
    (host.users.data.primary or {});

  seed = let
    c = user.interface.style.cursors;
  in
    resolveCursors (
      {
        inherit pkgs;
        inherit (c) size light dark;
      }
      // (
        if c.accent != null
        then {inherit (c) accent;}
        else {}
      )
      // (
        if c.variant != null
        then {inherit (c) variant;}
        else {}
      )
    )
    // {
      inherit (c) size accent variant light dark;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    size = mkOption {
      description = "Cursor size in pixels";
      default = seed.size;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursors.size or 24'';
      type = int;
    };

    accent = mkOption {
      description = "Cursor accent override (null = inherit from theme.accent)";
      default = seed.accent;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursors.accent or null'';
      type = nullOr str;
    };

    variant = mkOption {
      description = "Cursor variant override (null = inherit from theme.variant)";
      default = seed.variant;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursors.variant or null'';
      type = nullOr (attrsOf str);
    };

    light = mkOption {
      description = "Overrides for the light-polarity cursor set (name, package, size)";
      default = seed.light;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursors.light or {}'';
      type = attrsOf anything;
    };

    dark = mkOption {
      description = "Overrides for the dark-polarity cursor set (name, package, size)";
      default = seed.dark;
      defaultText = literalExpression ''host.users.data.primary.interface.style.cursors.dark or {}'';
      type = attrsOf anything;
    };

    resolved = mkOption {
      description = "Resolved cursor attrset ({ light, dark } each with name, package, size), derived from active options";
      default = resolveCursors (
        {
          inherit pkgs;
          size = cfg.size;
          light = cfg.light;
          dark = cfg.dark;
        }
        // (
          if cfg.accent != null
          then {inherit (cfg) accent;}
          else {}
        )
        // (
          if cfg.variant != null
          then {inherit (cfg) variant;}
          else {}
        )
      );
      defaultText = literalExpression "resolveCursors { inherit pkgs size light dark; } // optional accent variant";
      type = attrsOf anything;
      readOnly = true;
    };
  };
}
