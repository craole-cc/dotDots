{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "managers";
    mod = "niri";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;} // ctx.wantsNiri;
    };
    outputs = {
      programs.niri.enable = cfg.enable;
      services.iio-niri.enable = cfg.enable;
    };
  }
