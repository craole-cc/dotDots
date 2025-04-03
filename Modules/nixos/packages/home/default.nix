{ osConfig, ... }:
{
  home.stateVersion = osConfig.system.stateVersion;
  programs.home-manager.enable = true;
  imports = [
    ./bat
    ./helix
    ./hyprland
  ];
}
