{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkServices = {
    host,
    config,
    ...
  }: let
    #~@ User profile
    user = host.users.data.primary or {};

    #~@ Host interface
    wm = host.interface.windowManager    or null;
    de = host.interface.desktopEnvironment or null;
    dp = host.interface.displayProtocol  or "wayland";
    dm = host.interface.displayManager   or null;
    bar = host.interface.bar or user.interface.bar or null;

    #~@ Derived state
    session =
      if wm != null
      then wm
      else de;
    hasGui = de != null || wm != null;
    useDms = bar == "dms" && (wm == "niri" || wm == "hyprland");
  in {
    services = {
      #~@ Input
      iio-niri.enable = wm == "niri"; #? Sensor integration for niri

      #~@ Desktop environments
      desktopManager = {
        cosmic = {
          enable = de == "cosmic";
          showExcludedPkgsWarning = false;
        };

        gnome.enable = de == "gnome";
        plasma6.enable = de == "plasma";
      };

      #~@ Display manager
      displayManager = {
        autoLogin = {
          enable = user.autoLogin or false;
          user = user.name or null;
        };

        defaultSession =
          if (session == "hyprland" && config.programs.hyprland.withUWSM)
          then "hyprland-uwsm"
          else session;

        #? COSMIC native greeter — disabled when DMS active
        cosmic-greeter.enable = de == "cosmic" && !useDms;
        dms-greeter.enable = useDms;

        gdm = {
          enable = dm == "gdm" && !useDms;
          wayland = dp == "wayland";
        };

        sddm = {
          enable = dm == "sddm" && !useDms;
          wayland.enable = dp == "wayland";
        };

        ly.enable = dm == "ly";
      };

      #~@ Hardware
      udisks2 = optionalAttrs hasGui {
        enable = true;
        mountOnMedia = true; #? Auto-mount removable media under /media
      };
    };

    #~@ Systemd — suppress redundant TTY sessions when using GDM
    systemd.services = optionalAttrs (dm == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    # xdg.portal = {
    #   enable = true;
    #   config = {
    #     common."org.freedesktop.impl.portal.Settings" = ["darkman" "gnome"];
    #   };
    # };
  };

  exports = {inherit mkServices;};
in
  exports // {_rootAliases = exports;}
