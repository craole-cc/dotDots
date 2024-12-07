{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
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

  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      orca
      file-roller
      gnome-disk-utility
      zuki-themes
    ]
    ++ (with xfce; [
      catfish
      # gigolo
      # orage
      # xfburn
      # xfce4-appfinder
      xfce4-clipman-plugin
      xfce4-cpugraph-plugin
      xfce4-dict
      xfce4-fsguard-plugin
      # xfce4-genmon-plugin
      xfce4-netload-plugin
      xfce4-panel
      xfce4-pulseaudio-plugin
      xfce4-systemload-plugin
      xfce4-weather-plugin
      # xfce4-whiskermenu-plugin
      xfce4-xkb-plugin
      # xfdashboard
    ]);
}
