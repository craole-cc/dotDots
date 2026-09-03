{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "environments";
    mod = "cosmic";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;} // ctx.wantsGnome;
    };
    outputs = {
      services.desktopManager.cosmic = {
        inherit (cfg) enable;
        showExcludedPkgsWarning = false;
      };
    };
  }
