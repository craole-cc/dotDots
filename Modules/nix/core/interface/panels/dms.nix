{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panel";
    mod = "dms-shell";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  panel = config.${context.top}.resolved.interface.panel or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = panel == "dms-shell";
      };
    };
    outputs = {
      programs.dms-shell.enable = cfg.enable;
    };
  }
