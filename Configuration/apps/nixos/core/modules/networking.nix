{ specialArgs, lib, ... }:
let
  inherit (lib.lists) elem length;
  inherit (lib.attrsets) listToAttrs mapAttrs;
  inherit (specialArgs.host)
    name
    id
    devices
    access
    ;
  inherit (access) firewall;
  inherit (firewall) tcp udp;
in
{
  networking = {
    hostId = id;
    hostName = name;
    interfaces =
      mapAttrs
        (_: iface: {
          useDHCP = true;
        })
        (
          listToAttrs (
            map (iface: {
              name = iface;
              value = { };
            }) devices.network
          )
        );
    networkmanager = {
      enable = length devices.network >= 1;
      #TODO: take this from the host config
    };
    firewall = {
      enable = access.firewall.enable;
      allowedTCPPorts = tcp.ports;
      allowedUDPPorts = udp.ports;
      allowedTCPPortRanges = tcp.ranges;
      # allowedTCPPortRanges = [
      #   {
      #     from = 8760;
      #     to = 8769;
      #   }
      # ];
      allowedUDPPortRanges = udp.ranges;
    };
  };
}
