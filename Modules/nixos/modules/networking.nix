{
  specialArgs,
  lib,
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
  inherit (builtins) hashString substring;

  getHash = num: string: substring 0 num (hashString "md5" string);
  id = specialArgs.host.id or import specialArgs.paths.libraries.mkHash { string = name; };
in
{
  networking = {
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
    networkmanager = {
      enable = length devices.network >= 1;
      #TODO: take this from the host config
    };
    firewall = {
      enable = access.firewall.enable;
      allowedTCPPorts = tcp.ports;
      allowedUDPPorts = udp.ports;
      allowedTCPPortRanges = tcp.ranges;
      allowedUDPPortRanges = udp.ranges;
    };
  };
}
