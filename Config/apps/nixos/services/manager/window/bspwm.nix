# { config, lib, pkgs, ... }: with lib;
{ pkgs, ... }:

{
  services = {
    xserver.windowManager.bspwm = {
        enable = true;
        package = "pkgs.bspwm";
        sxhkd.package = "pkgs.sxhkd";
        #TODO# Find a better was to do this, preferably with a variable
        configFile = "../../../../tools/interface/bspwm/bspwmrc";
        sxhkd.configFile = "../../../../tools/interface/bspwm/sxhdrc";
      };
    xrdp.defaultWindowManager = "bspwm";
  };
}
