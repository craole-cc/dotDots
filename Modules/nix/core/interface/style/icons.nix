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
  sub = "icons";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything package str;
  inherit (lix.modules.core.style) resolveIcons;

  user =
    recursiveUpdate {
      interface.style.icons = {
        light = {};
        dark = {};
      };
    }
    (host.users.data.primary or {});

  seed = let
    i = user.interface.style.icons;
  in
    resolveIcons {
      inherit pkgs;
      inherit (i) light dark;
    }
    // {
      inherit (i) light dark;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    light = mkOption {
      description = "Overrides for the light-polarity icon theme (name, package)";
      default = seed.light;
      defaultText = literalExpression ''host.users.data.primary.interface.style.icons.light or {}'';
      type = attrsOf anything;
    };

    dark = mkOption {
      description = "Overrides for the dark-polarity icon theme (name, package)";
      default = seed.dark;
      defaultText = literalExpression ''host.users.data.primary.interface.style.icons.dark or {}'';
      type = attrsOf anything;
    };

    resolved = mkOption {
      description = "Resolved icon attrset ({ light, dark } each with name, package), derived from active options";
      default = resolveIcons {
        inherit pkgs;
        light = cfg.light;
        dark = cfg.dark;
      };
      defaultText = literalExpression "resolveIcons { inherit pkgs light dark; }";
      type = attrsOf anything;
      readOnly = true;
    };
  };
}
