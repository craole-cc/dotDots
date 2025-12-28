{
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkDefault;
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) optionals;

  networkDevices = host.devices.network or [];
  hasNetwork = networkDevices != [];
  access = host.access or {};
  firewall = access.firewall or {};
in {
  networking = {
    hostName = host.name or "nixos";
    hostId = host.id or null;
    networkmanager.enable = hasNetwork;
    nameservers = access.nameservers or [];
    interfaces = genAttrs networkDevices (_: {useDHCP = mkDefault hasNetwork;});
    firewall = {
      enable = firewall.enable or false;
      allowedTCPPorts = firewall.tcp.ports or [];
      allowedTCPPortRanges = firewall.tcp.ranges or [];
      allowedUDPPorts = firewall.udp.ports or [];
      allowedUDPPortRanges = firewall.udp.ranges or [];
    };
  };

  environment.systemPackages = optionals hasNetwork (with pkgs; [
    speedtest-cli
    speedtest-go
  ]);

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
