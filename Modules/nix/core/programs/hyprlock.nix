{
  config,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "hyprlock";
  cfg = config.${top}.${dom}.${mod};

  wm = config.${top}.interface.windowManager or null;

  inherit (lix.options.construction) mkEnable;
  inherit (lix.modules.construction) mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnable {
      description = "Hyprlock screen locker for Hyprland";
      condition = wm == "hyprland";
    };
  };

  config = mkIf cfg.enable {
    programs.${mod}.enable = cfg.enable;
  };
}
