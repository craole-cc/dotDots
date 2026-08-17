{
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) bool;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "clients";
    mod = "github";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
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
