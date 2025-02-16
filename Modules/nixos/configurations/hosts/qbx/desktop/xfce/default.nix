{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfgEnabled = config.dots.interface.desktop.environment == "xfce";
in {
  config = mkIf cfgEnabled {
    services.xserver = {
      #@ Enable XFCE desktop environment
      desktopManager.xfce.enable = true;

      #@ Enable LightDM (Lightweight Display Manager)
      displayManager.lightdm.enable = true;

      #@ Xterm is unnecessary since console is enabled automatically
      excludePackages = [pkgs.xterm];
    };

    #@ Exclude packages [optional]
    environment.xfce.excludePackages = with pkgs; [
      # xfce4-notifyd
      # xfce4-power-manager
      # xfce4-screensaver
      # xfce4-clipman-plugin
      # xfce4-datetime-plugin
      # xfce4-genmon-plugin
      # xfce4-mailwatch-plugin
      # xfce4-mount-plugin
      # xfce4-mpc-plugin
      # xfce4-netload-plugin
      # xfce4-places-plugin
      # xfce4-quicklauncher-plugin
      # xfce4-sensors-plugin
      # xfce4-smartbookmark-plugin
      # xfce4-systemload-plugin
      # xfce4-time-out-plugin
      # xfce4-verve-plugin
      # xfce4-wavelan-plugin
      # xfce4-weather-plugin
      # xfce4-whiskermenu-plugin
      # xfce4-windowck-plugin
      # xfce4-xkb-plugin
      # parole
      # ristretto
      # thunar-archive-plugin
      # thunar-media-tags-plugin
      # thunar-vcs-plugin
      # thunar-volman
      # xfce4-appfinder
      # xfce4-battery-plugin
      # xfce4-clipman
      # xfce4-dict
      # xfce4-diskperf-plugin
      # xfce4-fsguard-plugin
      # xfce4-genmon-plugin
      # xfce4-mixer
      # xfce4-mount-plugin
      # xfce4-notifyd
      # xfce4-panel
      # xfce4-power-manager
      # xfce4-pulseaudio-plugin
      # xfce4-screenshooter
      # xfce4-sensors-plugin
      # xfce4-session
      # xfce4-settings
      # xfce4-taskmanager
      # xfce4-terminal
      # xfce4-verve-plugin
      # xfce4-volumed-pulse
      # xfce4-weather-plugin
      # xfce4-xfwm4
      # xfconf
      # xfdesktop
      # xfburn
      # xfce4-about
    ];
  };
}
