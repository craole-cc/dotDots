{ pkgs, ... }:{
  services.xserver.desktopManager.plasma5.enable = true;
  environment.systemPackages = with pkgs; [
    materia-kde-theme
    plasma-browser-integration
  ];
}
