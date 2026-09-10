{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "tools";
    mod = "nh";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.nh.enable or false;
    };
    outputs.programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "daily";
      };
    };
  }
