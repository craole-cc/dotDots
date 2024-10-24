{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pa_applet
    cbatticon
    variety
    brightnessctl
    betterlockscreen
    # ddcutil
    pavucontrol
    udiskie
    volumeicon

  ];
}
