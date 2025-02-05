let
  ports = [3389];
in {
  services.xrdp = {
    enable = true;
    audio.enable = true;
    defaultWindowManager = "hyprland";
  };

  networking.firewall = {
    allowedTCPPorts = ports;
    allowedUDPPorts = ports;
  };
}
