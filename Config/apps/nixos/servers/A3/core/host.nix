{ ... }: {
  networking = {
    hostName = "A3";
    hostId = "1786a237";
    interfaces = {
      enp3s0.useDHCP = true;
      wlp4s0.useDHCP = true;
    };
  };
}
