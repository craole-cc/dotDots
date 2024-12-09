{ pkgs, ... }:{
  environment.systemPackages =
    with pkgs; if config.xserver.enable then
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
    ]) else [
      qalculate-qt
      wlprop
    ];
}
