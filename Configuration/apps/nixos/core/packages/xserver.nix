{ pkgs, ... }:
{
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
    ]);
}
