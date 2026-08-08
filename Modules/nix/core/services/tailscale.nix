{host, lib, ...}: let
  # Tailscale is the machine-to-machine VPN used for remote development,
  # recovery access, and swarm communication. Keep it separate from the
  # application VPN namespace configured by services/vpn.nix.
  enabled = lib.elem "vpn" (host.functionalities or []);
in {
  services.tailscale.enable = lib.mkIf enabled true;
}
