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
    mod = "direnv";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.direnv.enable or false;
    };
    outputs.programs.direnv = {
      enable = true;
      silent = true;
      mise.enable = true;
    };
  }
