{config, lib, pkgs, ...}: {
  # Development hosts need to run prebuilt language servers, editor helpers,
  # and other dynamically linked binaries that are not Nix-native.
  programs.nix-ld.enable = lib.mkDefault true;

  environment.systemPackages = [pkgs.nix-ld];
}
