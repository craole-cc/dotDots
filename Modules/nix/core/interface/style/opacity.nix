{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "opacity";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything float;
  inherit (lix.modules.core.style) resolveOpacity;

  user =
    recursiveUpdate {
      interface.style.opacity = {
        terminal = 0.9;
        popups = 0.95;
        light = {};
        dark = {};
      };
    }
    (host.users.data.primary or {});

  seed = let
    o = user.interface.style.opacity;
  in
    resolveOpacity {
      inherit (o) terminal popups light dark;
    }
    // {
      inherit (o) terminal popups light dark;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    terminal = mkOption {
      description = "Base terminal background opacity (0.0–1.0)";
      default = seed.terminal;
      defaultText = literalExpression ''host.users.data.primary.interface.style.opacity.terminal or 0.9'';
      type = float;
    };

    popups = mkOption {
      description = "Base popup/overlay background opacity (0.0–1.0)";
      default = seed.popups;
      defaultText = literalExpression ''host.users.data.primary.interface.style.opacity.popups or 0.95'';
      type = float;
    };

    light = mkOption {
      description = "Overrides for the light-polarity opacity set (terminal, popups)";
      default = seed.light;
      defaultText = literalExpression ''host.users.data.primary.interface.style.opacity.light or {}'';
      type = attrsOf anything;
    };

    dark = mkOption {
      description = "Overrides for the dark-polarity opacity set (terminal, popups)";
      default = seed.dark;
      defaultText = literalExpression ''host.users.data.primary.interface.style.opacity.dark or {}'';
      type = attrsOf anything;
    };

    resolved = mkOption {
      description = "Resolved opacity attrset ({ light, dark } each with terminal, popups), derived from active options";
      default = resolveOpacity {
        terminal = cfg.terminal;
        popups = cfg.popups;
        light = cfg.light;
        dark = cfg.dark;
      };
      defaultText = literalExpression "resolveOpacity { inherit terminal popups light dark; }";
      type = attrsOf anything;
      readOnly = true;
    };
  };
}
