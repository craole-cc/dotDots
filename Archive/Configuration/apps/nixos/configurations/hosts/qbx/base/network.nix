{ lib, ... }:
{
  networking = {
    hostName = "QBX";
    hostId = "32856885";
    networkmanager.enable = true;
    interfaces = {
      enp9s0.useDHCP = lib.mkDefault true;
      wlp8s0.useDHCP = lib.mkDefault true;
    };
  };
}
