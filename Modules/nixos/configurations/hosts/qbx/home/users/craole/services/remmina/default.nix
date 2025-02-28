{
  imports = [ ];
  services.remmina = {
    enable = true;
    systemdService.startupFlags = [ "--icon" ];
  };
}
