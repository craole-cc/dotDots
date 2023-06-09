{ lib, pkgs, ... }:

{
  imports = [];
  environment.systemPackages = with pkgs; [
    xorg.xev
    picom-next
    lxappearance
    rofi
    dmenu
    sxhkd
    numlockx
    wmctrl
    lxqt.lxqt-policykit # provides a default authentification client for policykit
    gnome.gnome-keyring libsecret libgnome-keyring gnome.seahorse
    xclip
  ];
}
