{ pkgs, osConfig, ... }:
{
  imports = [ ];
  home = {
    stateVersion = osConfig.system.stateVersion;
    packages = with pkgs; [ cowsay ];
  };
  programs = {
    home-manager.enable = true;
    atuin = {
      enable = true;
      daemon.enable = true;
      enableBashIntegration = true;
    };
  };
}
