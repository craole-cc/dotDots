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
  sub = "theme";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything nullOr package str;
  inherit (lix.modules.core.style) resolveThemes;

  user =
    recursiveUpdate {
      interface.style.theme = {
        accent = "teal";
        variant = {
          light = "latte";
          dark = "frappe";
        };
        light = {};
        dark = {};
      };
    }
    (host.users.data.primary or {});

  seed = let
    t = user.interface.style.theme;
  in
    resolveThemes {
      inherit pkgs;
      inherit (t) accent variant light dark;
    }
    // {
      inherit (t) accent variant light dark;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    accent = mkOption {
      description = "Catppuccin accent colour (e.g. \"teal\", \"blue\", \"mauve\")";
      default = seed.accent;
      defaultText = literalExpression ''host.users.data.primary.interface.style.theme.accent or "teal"'';
      type = str;
    };

    variant = mkOption {
      description = "Catppuccin variant per polarity ({ light = \"latte\"; dark = \"frappe\"|\"macchiato\"|\"mocha\"; })";
      default = seed.variant;
      defaultText = literalExpression ''
        host.users.data.primary.interface.style.theme.variant or
          { light = "latte"; dark = "frappe"; }
      '';
      type = attrsOf str;
    };

    light = mkOption {
      description = "Overrides merged into the light theme attrset (name, scheme, package, …)";
      default = seed.light;
      defaultText = literalExpression ''host.users.data.primary.interface.style.theme.light or {}'';
      type = attrsOf anything;
    };

    dark = mkOption {
      description = "Overrides merged into the dark theme attrset (name, scheme, package, …)";
      default = seed.dark;
      defaultText = literalExpression ''host.users.data.primary.interface.style.theme.dark or {}'';
      type = attrsOf anything;
    };

    resolved = mkOption {
      description = "Resolved theme attrset ({ light, dark } each with name, scheme, variant, package), derived from active options";
      default = resolveThemes {
        inherit pkgs;
        accent = cfg.accent;
        variant = cfg.variant;
        light = cfg.light;
        dark = cfg.dark;
      };
      defaultText = literalExpression "resolveThemes { inherit pkgs accent variant light dark; }";
      type = attrsOf anything;
      readOnly = true;
    };
  };
}
