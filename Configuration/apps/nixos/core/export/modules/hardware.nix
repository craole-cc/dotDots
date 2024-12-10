{ specialArgs, lib, ... }:
let
  inherit (lib.lists) elem;
  inherit (lib.attrsets) listToAttrs mapAttrs;
  inherit (specialArgs.host)
    name
    id
    modules
    cpu
    devices
    access
    ;
  inherit (access) firewall;
  inherit (firewall) tcp udp;
  inherit (cpu) brand;
in
{
  boot = {
    initrd = {
      availableKernelModules = modules;
      luks.devices = devices.luks;
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules =
      if
        (elem brand [
          "intel"
          "amd"
          # "x86"
        ])
      then
        [ "kvm-${brand}" ]
      else
        [ ];
    extraModulePackages = [ ];
  };

  inherit (devices) fileSystems swapDevices;

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

    firewall = {
      enable = if firewall ? enable then firewall.enable else false;
      allowedTCPPorts = tcp.ports;
      allowedUDPPorts = udp.ports;
      allowedTCPPortRanges = tcp.ranges;
      allowedUDPPortRanges = udp.ranges;
    };
  };
}
