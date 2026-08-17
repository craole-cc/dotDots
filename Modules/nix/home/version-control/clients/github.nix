{
  config,
  lix,
  top,
  ...
}: let
  dom = "version-control";
  sub = "clients";
  mod = "github";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.types.primitives) bool;
in
  mkConfig {
    inherit config top dom sub mod;

    options = {
      enable = mkEnableOption mod // {default = true;};

      dash.enable = mkOption {
        type = bool;
        default = cfg.enable;
        description = "Enable gh-dash GitHub CLI dashboard";
      };
    };

    outputs = {
      programs = {
        gh.enable = cfg.enable;
        gh-dash.enable = cfg.dash.enable;
      };
    };
  }
