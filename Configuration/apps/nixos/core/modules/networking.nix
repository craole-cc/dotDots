{ specialArgs, lib, ... }:
let
  inherit (lib.lists) elem;
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
      enable = true;
      #TODO: take this from the host config
    };
    firewall = {
      enable = firewall.enable or false;
      allowedTCPPorts = tcp.ports;
      allowedUDPPorts = udp.ports;
      allowedTCPPortRanges = tcp.ranges;
      allowedUDPPortRanges = udp.ranges;
    };
  };
}
