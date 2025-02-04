{ ... }:

{
  imports = [ ./xdm.nix ];
  services.xserver.displayManager.gdm.enable = true;
}
