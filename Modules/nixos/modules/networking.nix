{
  networking = {
    hostId = with builtins; substring 0 8 (hashString "md5" config.networking.hostName);
    networkmanager.enable = true;
  };
}
