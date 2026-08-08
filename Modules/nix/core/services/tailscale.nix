{config, lib, ...}: {
  # Tailscale is the machine-to-machine VPN used for remote development,
  # recovery access, and swarm communication. Keep it separate from the
  # application VPN namespace configured by services/vpn.nix.
  # QBX is explicitly a Tailscale-capable host; this must not depend on the
  # normalized host record being available as a module argument.
  services.tailscale.enable = lib.mkIf (config.networking.hostName == "QBX") true;
}
