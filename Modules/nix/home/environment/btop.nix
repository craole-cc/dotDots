{
  apps,
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "btop";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = apps.needs "btop";
    };
    outputs.programs.btop.enable = true;
  }
