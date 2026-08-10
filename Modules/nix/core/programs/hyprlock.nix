{
  config,
  lix,
  lib,
  top,
  ...
}: let
  dom = "programs";
  mod = "hyprlock";
  cfg = config.${top}.resolved.${dom}.${mod};

  wm = config.${top}.resolved.interface.windowManager or null;

  inherit (lix.options.construction) mkEnable;
  inherit (lix.modules.construction) mkIf;
  payload = {
    programs.${mod}.enable = cfg.enable;
    };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.${dom}.${mod} = {
    enable = mkEnable {
      description = "Hyprlock screen locker for Hyprland";
      condition = wm == "hyprland";
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
