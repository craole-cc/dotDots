{pkgs, ...}: {
  # Development hosts need to run prebuilt language servers, editor helpers,
  # and other dynamically linked binaries that are not Nix-native.
  programs.nix-ld.enable = true;

  environment.systemPackages = [pkgs.nix-ld];

  # QBX is a Tailscale-capable host. Keep this separate from the application
  # VPN namespace configured by services/vpn.nix.
  services.tailscale.enable = true;
}
