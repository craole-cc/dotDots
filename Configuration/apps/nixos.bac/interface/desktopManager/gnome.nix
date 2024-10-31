{ pkgs, ... }:

{
  imports = [ ../displayManager/gdm.nix ];
  services.xserver.desktopManager.gnome.enable = true;
}
