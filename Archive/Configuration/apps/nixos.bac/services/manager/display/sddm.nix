{ ... }:
{
  imports = [ ./default.nix ];
  services.xserver.displayManager.sddm.enable = true;
}
