{...}: {
  # QBX is a Tailscale-capable host. Tailscale is required for remote
  # development, recovery access, and swarm communication. This is separate
  # from the application VPN namespace configured by services/vpn.nix.
  services.tailscale.enable = true;
}
