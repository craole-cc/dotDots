{...}: {
  imports = [./default.nix];
  services.xserver.displayManager.gdm.enable = true;
}
