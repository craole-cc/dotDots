{ lib, pkgs, ... }:

{
  imports = [
    ../../services/xserver
    ../../services/xserver
  ];
  # services = {
  # xserver = {
  #   layout = "us";
  #   xkbVariant = "";
  #   enable = true;
  #   autorun = true;
  #   desktopManager.xterm.enable = false;
  #   libinput.enable = true;
  # };
  # autorandr.enable = true;
  #@ Compositor
  # picom = {
  #   enable = true;
  #   fade = true;
  #   inactiveOpacity = 0.9;
  #   shadow = true;
  #   fadeDelta = 4;
  # };
  #@ USB Automount
  # gvfs = {
  #   enable = true;
  #   package = lib.mkForce pkgs.gnome3.gvfs;
  # };
  # };

  #@ Authentication
  # xsession.profileExtra = ''
  #   eval $(${pkgs.gnome3.gnome-keyring}/bin/gnome-keyring-daemon --daemonize --components=ssh,secrets)
  #   export SSH_AUTH_SOCK
  # '';

  #@ Packages
  environment.systemPackages = with pkgs; [
    # ddcutil
    brightnessctl

    betterlockscreen
    picom-next
    pavucontrol
    xorg.xev
    lxappearance
    volumeicon
    numlockx
    udiskie
    rofi
    dmenu
    sxhkd
    wmctrl
    # lxqt.lxqt-policykit # provides a default authentification client for policykit
    # gnome.gnome-keyring libsecret libgnome-keyring gnome.seahorse
  ];
}
