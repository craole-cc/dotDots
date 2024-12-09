{ pkgs, config, ... }:
let
  isX11 = config.services.xserver.enable;
in
{
  environment.systemPackages =
    if isX11 then
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
      ])
    else
      [ ];
      
  programs =
    if isX11 then
      {
        firefox = {
          # enable = true;
        };
      }
    else
      { };
}
