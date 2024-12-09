{ pkgs, ... }:{
  environment.systemPackages =
    with pkgs; if config.services.xserver.enable then
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
