{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  enable = config.services.xserver.enable;
in
{
  config = mkIf enable {
    environment.systemPackages =
      with pkgs;
      [
        qalculate-gtk
        wmctrl
        variety
      ]
      ++ (with xorg; [
        xprop
        xdotool
        xinput
        xrandr
        xev
      ]);

    programs = {
      firefox = {
        enable = true;
      };
    };
  };
}
