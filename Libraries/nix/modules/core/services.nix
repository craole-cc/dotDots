{_, ...}: let
  inherit (_.attrsets.construction) optionalAttrs;

  exports = {
    internal = {inherit mkServices;};
    external = {mkCoreServices = mkServices;};
  };

  /**
    Build a NixOS configuration fragment for display/session services.

    Derives the active session name from `defaultSession`, then
    `windowManager`, then `desktopEnvironment`, with a `hyprland-uwsm`
    override when `config.programs.hyprland.withUWSM` is true. Enables the
    appropriate display manager, desktop-manager modules, auto-login, DMS
    greeter detection, GDM TTY suppression, and GUI-gated udisks2.

    XDG portal configuration is intentionally excluded - portal.nix owns
    that slice.

    # Type
  ```nix
    mkServices :: {
      config             :: AttrSet,
      windowManager      :: String | null,
      desktopEnvironment :: String | null,
      displayProtocol    :: String,
      displayManager     :: String | null,
      defaultSession     :: String | null,
      panel              :: String | null,
      autoLogin          :: Bool,
      autoLoginUser      :: String | null,
    } -> AttrSet
  ```

    # Examples
  ```nix
    mkServices {
      inherit config;
      windowManager  = "hyprland";
      displayManager = "sddm";
      displayProtocol = "wayland";
      defaultSession = null;
      panel = null;
      autoLogin = false;
      autoLoginUser = null;
      desktopEnvironment = null;
    }
    # => {
    #   services.displayManager.defaultSession = "hyprland-uwsm"; # when withUWSM
    #   services.displayManager.sddm = { enable = true; wayland.enable = true; };
    #   services.iio-niri.enable = false;
    #   ...
    # }
  ```
  */
  mkServices = {
    config,
    windowManager ? null,
    desktopEnvironment ? null,
    displayProtocol ? "wayland",
    displayManager ? null,
    defaultSession ? null,
    panel ? null,
    autoLogin ? false,
    autoLoginUser ? null,
    ...
  }: let
    useDms = panel == "dms-shell" && (windowManager == "niri" || windowManager == "hyprland");
    hasGui = desktopEnvironment != null || windowManager != null;

    # Session resolution: explicit override > wm > de, then hyprland-uwsm
    # promotion when withUWSM is active.
    baseSession =
      if defaultSession != null
      then defaultSession
      else if windowManager != null
      then windowManager
      else desktopEnvironment;

    resolvedSession =
      if windowManager == "hyprland" && config.programs.hyprland.withUWSM
      then "hyprland-uwsm"
      else baseSession;
  in {
    services = {
      #~@ Input
      iio-niri.enable = windowManager == "niri";

      #~@ Desktop environments
      desktopManager = {
        cosmic = {
          enable = desktopEnvironment == "cosmic";
          showExcludedPkgsWarning = false;
        };
        gnome.enable = desktopEnvironment == "gnome";
        plasma6.enable = desktopEnvironment == "plasma";
      };

      #~@ Display manager
      displayManager = {
        defaultSession = resolvedSession;

        autoLogin = {
          enable = autoLogin;
          user = autoLoginUser;
        };

        cosmic-greeter.enable = desktopEnvironment == "cosmic" && !useDms;
        dms-greeter.enable = useDms || displayManager == "dms-greeter";

        gdm = {
          enable = displayManager == "gdm" && !useDms;
        };

        sddm = {
          enable = displayManager == "sddm" && !useDms;
          wayland.enable = displayProtocol == "wayland";
        };

        ly.enable = displayManager == "ly";
      };

      #~@ Hardware
      udisks2 = optionalAttrs hasGui {
        enable = true;
        mountOnMedia = true;
      };
    };

    #~@ Suppress redundant TTY sessions when GDM is the display manager
    systemd.services = optionalAttrs (displayManager == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };
in
  exports.internal // {__rootAliases = exports.external;}
