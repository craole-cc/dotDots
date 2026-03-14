{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.de == "gnome") {
    services = {
      desktopManager.gnome.enable = true;
      # displayManager.gdm.enable = true;
    };

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
