{ config, ... }:
let
  cfg = config.dots.interface.display;
  manager = cfg.manager;
  wayland = cfg.protocol == "wayland";
in
{
  config =
    if manager == "sddm" then
      {
        services.displayManager.sddm = {
          enable = true;
          inherit wayland;
        };
      }
    else if manager == "gdm" then
      {
        services.xserver.displayManager.gdm = {
          enable = true;
          inherit wayland;
        };
      }
    else if manager == "lightdm" then
      {
        services.xserver.displayManager.lightdm = {
          enable = true;
        };
      }
    else
      { };

}
