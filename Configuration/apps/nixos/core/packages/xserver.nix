{ pkgs, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      qalculate-gtk
      wmctrl
    ]
    ++ (with xorg; [
      xprop
      xdotool
      xinput
      xrandr
    ]);
}
