{ ... }: {
  imports = [./default.nix];
  services.xserver.displayManager.lightdm.enable = true;
}
