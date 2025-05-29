{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dots.interface) display desktop;
  cfgEnabled = desktop.environment == "gnome" && display.protocol == "xserver";
  nvidiaEnabled = config.hardware.nvidia.modesetting.enable;
in
{
  config = mkIf cfgEnabled {
    services.xserver = {
      enable = true;
      videoDrivers = if nvidiaEnabled then [ "nvidia" ] else [ ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
