{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "hyprlock";
  };
  inherit (context) cfg mod top;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  wm = config.${top}.resolved.interface.windowManager or null;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Hyprlock screen locker for Hyprland";
        condition = wm == "hyprland";
      };
    };
    outputs = {
      programs.${mod}.enable = cfg.enable;
    };
  }
