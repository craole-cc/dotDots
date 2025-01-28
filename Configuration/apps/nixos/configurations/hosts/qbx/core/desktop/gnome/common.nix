{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfgEnabled = config.dots.interface.desktop.environment == "gnome";
in
{
  config = mkIf cfgEnabled {
    services.xserver = {
      #@ Enable GNOME desktop environment
      desktopManager.gnome.enable = true;

      #@ Enable GDM (GNOME Display Manager)
      displayManager.gdm.enable = true;

      #@ Xterm is unnecessary since console is enabled automatically
      excludePackages = [ pkgs.xterm ];
    };

    #@ Exclude packages [optional]
    environment.gnome.excludePackages = with pkgs; [
      # baobab
      epiphany
      # evince # Document Viewer
      # geary # Email Client
      gnome-text-editor
      # gnome-calculator
      # gnome-calendar
      # gnome-characters
      # gnome-clocks
      # gnome-connections # Remote desktop client
      # gnome-console  # Ensure a terminal is installed (ghostty, kitty, etc.)
      # gnome-contacts # Integrated address book
      # gnome-font-viewer
      # gnome-logs
      # gnome-maps
      # gnome-music
      # gnome-system-monitor
      # gnome-tour # GNOME Tour (welcome app) GNOME Shell detects the .desktop file on first log-in.
      # gnome-weather
      # loupe
      # nautilus
      # gnome-connections
      simple-scan
      snapshot
      totem # Videos
      yelp
    ];
  };
}
