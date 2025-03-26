{
  specialArgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.lists) length;
  inherit (lib.attrsets) listToAttrs mapAttrs;
  inherit (specialArgs.host)
    name
    devices
    access
    ;
  inherit (access) firewall;
  inherit (firewall) tcp udp;
  inherit (config.DOTS.lib.helpers) mkHash;
  id = specialArgs.host.id or mkHash 8 name;
  nameservers =
    access.nameservers or [
      "1.1.1.1" # Cloudflare DNSa
      "1.0.0.1" # Cloudflare DNSb
      "8.8.8.8" # Google DNS
      "9.9.9.9" # Quad 9
    ];
in
{
  networking = {
    inherit nameservers;
    hostId = id;
    hostName = name;
    interfaces =
      mapAttrs
        (_: _iface: {
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
    networkmanager.enable = length devices.network >= 1;
    firewall = {
      enable = access.firewall.enable;
      allowedTCPPorts = tcp.ports;
      allowedUDPPorts = udp.ports;
      allowedTCPPortRanges = tcp.ranges;
      allowedUDPPortRanges = udp.ranges;
    };
  };
}
