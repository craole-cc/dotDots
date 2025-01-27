{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfgEnabled =
    config.dots.interface.desktop.environment == "gnome"
    && config.dots.interface.display.protocol == "xserver";
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
