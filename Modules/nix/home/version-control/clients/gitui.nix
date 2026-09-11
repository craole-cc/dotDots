{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "clients";
    mod = "gitui";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.gitui.enable or false;
    };
    outputs.programs.gitui.enable = cfg.enable;
  }
