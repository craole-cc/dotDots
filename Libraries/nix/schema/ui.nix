{lib, ...}: let
  inherit (lib.attrsets) attrNames recursiveUpdate hasAttr optionalAttrs;
  inherit (lib.lists) elem head;

  __exports = {
    internal = {
      inherit
        mkUI
        defaults
        displayManagers
        desktopEnvironments
        windowManagers
        normalizeInterface
        ;
    };
    external = {
      mkUISchema = mkUI;
      normalizeUISchema = normalizeInterface;
    };
  };

  mkUI = {
    user,
    host,
  }: let
    mergedInterface =
      recursiveUpdate
      (host.interface or {})
      (user.interface or {});
  in
    normalizeInterface mergedInterface;

  defaults = {
    interface = {
      appLauncher = null;
      bar = null;
      defaultSession = null;
      desktopEnvironment = "plasma";
      desktopShell = null;
      displayManager = "sddm";
      displayProtocol = "wayland";
      fileManager = "yazi";
      notificationDaemon = "mako";
      shell = "bash";
      shellPrompt = "starship";
      terminal = "ghostty";
      windowManager = "hyprland";
      windowShell = null;
      keyboard = {
        modifier = "SUPER";
        swapCapsEscape = true;
      };
    };

    registry = {
      displayProtocols = ["wayland" "xorg"];
      displayManagers = attrNames displayManagers;
      desktopShell = null;
      notificationDaemon = null;
      fileManager = null;
      terminal = null;
      appLauncher = null;
    };
  };

  displayManagers = {
    gdm = {
      supported = ["wayland" "xorg"];
      type = "gui";
      base = "c";
      maturity = "stable";
      vibe = "gnome-first";
    };
    greetd = {
      supported = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "rust";
      maturity = "stable";
      vibe = "minimal-unixy";
    };
    lemurs = {
      supported = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "rust";
      maturity = "young";
      vibe = "tui-fancy";
    };
    lightdm = {
      supported = ["wayland" "xorg"];
      type = "gui";
      base = "c";
      maturity = "legacy";
      vibe = "swiss-army";
    };
    ly = {
      supported = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "zig";
      maturity = "niche";
      vibe = "aesthetic-min";
    };
    sddm = {
      supported = ["wayland" "xorg"];
      type = "gui";
      base = "cpp";
      maturity = "stable";
      vibe = "qt-kde";
    };
  };

  desktopEnvironments = {
    gnome = {
      displayProtocol = {
        supported = ["wayland" "xorg"];
        preferred = "wayland";
      };
      displayManager = {
        supported = ["gdm" "greetd" "lemurs" "lightdm" "ly" "sddm"];
        preferred = "gdm";
      };
      desktopShell = "gnome-shell";
      notificationDaemon = "gnome-shell";
      fileManager = "nautilus";
      terminal = "gnome-terminal";
      appLauncher = "gnome-shell-overview";
    };

    plasma = {
      displayProtocol = {
        supported = ["wayland" "xorg"];
        preferred = "wayland";
      };
      displayManager = {
        supported = ["sddm" "gdm" "lightdm" "greetd" "lemurs" "ly"];
        preferred = "sddm";
      };
      desktopShell = "plasmashell";
      notificationDaemon = "plasmashell";
      fileManager = "dolphin";
      terminal = "konsole";
      appLauncher = "krunner";
    };

    cosmic = {
      displayProtocol = {
        supported = ["wayland"];
        preferred = "wayland";
      };
      displayManager = {
        supported = ["cosmic-greeter" "gdm" "greetd" "lemurs" "sddm" "ly"];
        preferred = "cosmic-greeter";
      };
      desktopShell = "cosmic-shell";
      notificationDaemon = "cosmic-notifications";
      fileManager = "cosmic-files";
      terminal = "cosmic-terminal";
      appLauncher = "cosmic-launcher";
    };

    pantheon = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "gala";
      notificationDaemon = "notification-daemon";
      fileManager = "pantheon-files";
      terminal = "pantheon-terminal";
      appLauncher = "slingshot";
    };

    cinnamon = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "cinnamon";
      notificationDaemon = "cinnamon";
      fileManager = "nemo";
      terminal = "gnome-terminal";
      appLauncher = "cinnamon-menu";
    };

    xfce = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "xfce4-panel";
      notificationDaemon = "xfce4-notifyd";
      fileManager = "thunar";
      terminal = "xfce4-terminal";
      appLauncher = "xfce4-appfinder";
    };
  };

  windowManagers = let
    forWayland = {
      displayProtocol = {
        supported = ["wayland"];
        preferred = "wayland";
      };
      displayManager = {
        supported = [
          "dms-greeter"
          "gdm"
          "greetd"
          "lemurs"
          "lightdm"
          "ly"
          "sddm"
        ];
        preferred = "dms-greeter";
      };
      notificationDaemon = "mako";
      fileManager = "thunar";
      terminal = "kitty";
      appLauncher = "vicinae";
    };
  in {
    hyprland = {
      inherit
        (forWayland)
        displayManager
        displayProtocol
        notificationDaemon
        fileManager
        terminal
        appLauncher
        ;
      desktopShell = "hyprland";
      defaultSession="hyprland-"
    };

    niri = {
      inherit
        (forWayland)
        displayManager
        displayProtocol
        notificationDaemon
        fileManager
        terminal
        appLauncher
        ;
      desktopShell = "niri";
    };

    sway = {
      inherit
        (forWayland)
        displayManager
        displayProtocol
        notificationDaemon
        fileManager
        terminal
        appLauncher
        ;
      desktopShell = "sway";
    };

    river = {
      inherit
        (forWayland)
        displayManager
        displayProtocol
        notificationDaemon
        fileManager
        terminal
        appLauncher
        ;
      desktopShell = "river";
    };

    i3 = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "i3";
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "kitty";
      appLauncher = "rofi";
    };

    bspwm = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "bspwm";
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "kitty";
      appLauncher = "rofi";
    };

    qtile = {
      displayProtocol = {
        supported = ["wayland" "xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "qtile";
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "alacritty";
      appLauncher = "rofi";
    };

    awesome = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "awesome";
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "alacritty";
      appLauncher = "rofi";
    };

    xmonad = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "xmonad";
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "alacritty";
      appLauncher = "rofi";
    };

    openbox = {
      displayProtocol = {
        supported = ["xorg"];
        preferred = "xorg";
      };
      displayManager = {
        supported = ["lightdm" "gdm" "sddm"];
        preferred = "lightdm";
      };
      desktopShell = "openbox";
      notificationDaemon = "xfce4-notifyd";
      fileManager = "thunar";
      terminal = "xfce4-terminal";
      appLauncher = "rofi";
    };
  };

  normalizeInterface = interface: let
    default = defaults.interface // interface;

    desktopEnvironment =
      optionalAttrs (
        (interface.desktopEnvironment != null)
        && (hasAttr interface.desktopEnvironment desktopEnvironments)
      )
      {
        name = interface.desktopEnvironment;
        kind = "desktopEnvironment";
        config = desktopEnvironments.${default.desktopEnvironment};
      };

    windowManager =
      optionalAttrs (
        (interface.windowManager != null)
        && (hasAttr interface.windowManager windowManagers)
      )
      {
        name = interface.windowManager;
        kind = "windowManager";
        config = windowManagers.${interface.windowManager};
      };

    displayProtocol =
      interface.displayProtocol or
      desktopEnvironment.displayProtocol.preferred or
      windowManager.displayProtocol.preferred or
      default.displayProtocol;
    #TODO: Validate against supported

    desktopShell =
      interface.desktopShell or
      desktopEnvironment.desktopShell or
      windowManager.desktopShell or
      default.desktopShell;

    notificationDaemon =
      interface.notificationDaemon or
      desktopEnvironment.notificationDaemon or
      windowManager.notificationDaemon or
      default.notificationDaemon;

    fileManager = default.fileManager;
    terminal = default.terminal;
    appLauncher = default.appLauncher;

    defaultSession =
      if base.defaultSession != null
      then base.defaultSession
      else if windowManager != null
      then windowManager
      else if desktopEnvironment != null
      then desktopEnvironment
      else null;

    selectedInterface =
      if desktopEnvironment != null && hasAttr desktopEnvironment desktopEnvironments
      then {
        name = desktopEnvironment;
        kind = "desktopEnvironment";
        config = desktopEnvironments.${desktopEnvironment};
      }
      else if windowManager != null && hasAttr windowManager windowManagers
      then {
        name = windowManager;
        kind = "windowManager";
        config = windowManagers.${windowManager};
      }
      else null;

    # displayProtocol =
    #   if selectedInterface != null
    #   then
    #     if displayProtocolInput != null && elem displayProtocolInput selectedInterface.config.supportedProtocol
    #     then displayProtocolInput
    #     else selectedInterface.config.preferredProtocol
    #   else if displayProtocolInput != null
    #   then displayProtocolInput
    #   else defaultDisplayProtocol;

    displayManager =
      if desktopEnvironment ? displayManager
      then desktopEnvironment.displayManager
      else if windowManager ? displayManager
      then windowManager.displayManager
      else defaultDisplayManager;

    desktopShell =
      if desktopShellInput != null
      then desktopShellInput
      else if selectedInterface != null
      then selectedInterface.config.desktopShell
      else null;

    notificationDaemon =
      if notificationDaemonInput != null
      then notificationDaemonInput
      else if selectedInterface != null
      then selectedInterface.config.notificationDaemon
      else null;

    fileManager =
      if fileManagerInput != null
      then fileManagerInput
      else if selectedInterface != null
      then selectedInterface.config.fileManager
      else null;

    terminal =
      if terminalInput != null
      then terminalInput
      else if selectedInterface != null
      then selectedInterface.config.terminal
      else null;

    appLauncher =
      if appLauncherInput != null
      then appLauncherInput
      else if selectedInterface != null
      then selectedInterface.config.appLauncher
      else null;
  in
    defaults.interface
    // interface
    // {
      inherit
        defaultSession
        desktopEnvironment
        windowManager
        displayProtocol
        displayManager
        desktopShell
        notificationDaemon
        fileManager
        terminal
        appLauncher
        ;
      interfaces = {
        inherit
          desktopEnvironments
          windowManagers
          displayManagers
          ;
      };
    };
in
  __exports.internal // {_rootAliases = __exports.external;}
