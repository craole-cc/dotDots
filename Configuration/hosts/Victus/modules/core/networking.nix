{
  lib,
  host,
  ...
}:
let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.modules) mkDefault;
  inherit (host.devices) network;

  # Helper to build simple DHCP interfaces from host.devices.network
  mkInterface = _: { useDHCP = mkDefault true; };
in
{
  networking = {
    # System hostname
    hostName = host.name;

    # 32-bit host ID (ZFS requirement)
    hostId = host.id;

    # DNS Nameservers from host config
    inherit (host.access) nameservers;

    # Enable NetworkManager if interfaces are defined
    networkmanager.enable = network != [ ];

    # Generate interface configurations
    interfaces = genAttrs network mkInterface;

    firewall =
      let
        inherit (host.access.firewall) enable tcp udp;
      in
      {
        inherit enable;

        # TCP Configuration
        allowedTCPPorts = tcp.ports;
        allowedTCPPortRanges = tcp.ranges;

        # UDP Configuration
        allowedUDPPorts = udp.ports;
        allowedUDPPortRanges = udp.ranges;
      };
  };
}
