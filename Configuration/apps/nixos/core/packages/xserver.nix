{ pkgs, config, ... }:
if config.services.xserver.enable then
  {
    environment.systemPackages =
      with pkgs;
      [
        brave
        qalculate-gtk
        wmctrl
        variety
      ]
      ++ (with xorg; [
        xprop
        xdotool
        xinput
        xrandr
      ]);
    programs = {
      firefox = {
        # enable = true;
      };
    };
  }
else
  { }
