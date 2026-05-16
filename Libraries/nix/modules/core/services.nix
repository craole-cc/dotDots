{_, ...}: let
  inherit (_.attrsets.construction) optionalAttrs;

  exports = {
    internal = {inherit mkServices;};
    external = {
      mkCoreServices = mkServices;
    };
  };

  # mkServices = {
  #   host,
  #   config,
  #   ...
  # }: let
  #   #~@ User profile
  #   user = host.users.data.primary or {};

  #   #~@ Host interface
  #   wm = host.interface.windowManager or null;
  #   de = host.interface.desktopEnvironment or null;
  #   dp = host.interface.displayProtocol or "wayland";
  #   dm = host.interface.displayManager or null;
  #   bar = host.interface.bar or user.interface.bar or null;

  #   #~@ Derived state
  #   session =
  #     if wm != null
  #     then wm
  #     else de;
  #   hasGui = de != null || wm != null;
  #   useDms = bar == "dms" && (wm == "niri" || wm == "hyprland");
  # in {
  #   services = {
  #     #~@ Input
  #     iio-niri.enable = wm == "niri"; # ? Sensor integration for niri

  #     #~@ Desktop environments
  #     desktopManager = {
  #       cosmic = {
  #         enable = de == "cosmic";
  #         showExcludedPkgsWarning = false;
  #       };

  #       gnome.enable = de == "gnome";
  #       plasma6.enable = de == "plasma";
  #     };

  #     #~@ Display manager
  #     displayManager = {
  #       autoLogin = {
  #         enable = user.autoLogin or false;
  #         user = user.name or null;
  #       };

  #       defaultSession =
  #         if (session == "hyprland" && config.programs.hyprland.withUWSM)
  #         then "hyprland-uwsm"
  #         else session;

  #       #? COSMIC native greeter - disabled when DMS active
  #       cosmic-greeter.enable = de == "cosmic" && !useDms;
  #       dms-greeter.enable = useDms;

  #       gdm = {
  #         enable = dm == "gdm" && !useDms;
  #         wayland = dp == "wayland";
  #       };

  #       sddm = {
  #         enable = dm == "sddm" && !useDms;
  #         wayland.enable = dp == "wayland";
  #       };

  #       ly.enable = dm == "ly";
  #     };

  #     #~@ Hardware
  #     udisks2 = optionalAttrs hasGui {
  #       enable = true;
  #       mountOnMedia = true; # ? Auto-mount removable media under /media
  #     };
  #   };

  #   #~@ Systemd — suppress redundant TTY sessions when using GDM
  #   systemd.services = optionalAttrs (dm == "gdm") {
  #     "getty@tty1".enable = false;
  #     "autovt@tty1".enable = false;
  #   };

  #   xdg.portal = {
  #     enable = true;
  #     #   config = {
  #     #     common."org.freedesktop.impl.portal.Settings" = ["darkman" "gnome"];
  #     #   };
  #   };
  # };
  mkServices = {
    host,
    config,
    windowManager ? null,
    desktopEnvironment ? null,
    displayProtocol ? "wayland",
    displayManager ? null,
    panel ? null,
    autoLogin ? false,
    autoLoginUser ? null,
    ...
  }: let
    useDms = panel == "dms-shell" && (windowManager == "niri" || windowManager == "hyprland");
    session =
      if windowManager != null
      then windowManager
      else desktopEnvironment;
    hasGui = desktopEnvironment != null || windowManager != null;
    defaultSession =
      if windowManager == "hyprland" && config.programs.hyprland.withUWSM
      then "hyprland-uwsm"
      else session;
  in {
    services = {
      iio-niri.enable = windowManager == "niri";

      desktopManager = {
        cosmic = {
          enable = desktopEnvironment == "cosmic";
          showExcludedPkgsWarning = false;
        };
        gnome.enable = desktopEnvironment == "gnome";
        plasma6.enable = desktopEnvironment == "plasma";
      };

      displayManager = {
        inherit defaultSession;
        autoLogin = {
          enable = autoLogin;
          user = autoLoginUser;
        };
        cosmic-greeter.enable = desktopEnvironment == "cosmic" && !useDms;
        dms-greeter.enable = useDms || displayManager == "dms-greeter";
        gdm = {
          enable = displayManager == "gdm" && !useDms;
          wayland = displayProtocol == "wayland";
        };
        sddm = {
          enable = displayManager == "sddm" && !useDms;
          wayland.enable = displayProtocol == "wayland";
        };
        ly.enable = displayManager == "ly";
      };

      udisks2 = optionalAttrs hasGui {
        enable = true;
        mountOnMedia = true;
      };
    };

    systemd.services = optionalAttrs (displayManager == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    xdg.portal.enable = true;
  };
in
  exports.internal // {__rootAliases = exports.external;}
