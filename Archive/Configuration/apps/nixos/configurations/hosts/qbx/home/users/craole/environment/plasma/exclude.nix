{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault;
  cfg = config.dots.env.gnome;
in
{
  config = mkIf cfg.enable {
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

    services = {
      xserver.excludePackages = [ pkgs.xterm ];
      gnome = { };
    };
  };
}
