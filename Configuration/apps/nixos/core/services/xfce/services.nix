{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      # excludePackages = [ pkgs.xterm ];
      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick = {
            enable = true;
            theme.name = "Zukitre-dark";
          };
        };
        sessionCommands = ''
          test -f ~/.xinitrc && . ~/.xinitrc
        '';
      };
      desktopManager.xfce.enable = true;
    };
  };
}
