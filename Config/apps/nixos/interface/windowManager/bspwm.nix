# { config, lib, pkgs, ... }: with lib;
{ pkgs, ... }:

{
  services.xserver = {
    desktopManager = {
      xfce = {
        enable = true;
        enableXfwm = false;
      };
    };
    windowManager = {
      bspwm = {
        enable = true;
        # package = "pkgs.bspwm";
        # sxhkd.package = "pkgs.sxhkd";
        configFile = "../../tools/interface/bspwm/bspwmrc";
        sxhkd.configFile = "/store/DOTS/Config/tools/interface/bspwm/sxhdrc";
      };
    };
  };
  services.xrdp.defaultWindowManager = "bspwm";
}
