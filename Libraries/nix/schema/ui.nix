{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate hasAttr;
  inherit (lib.lists) elem;

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

  interfacePartsDefaults = {
    desktopEnvironment = null;
    windowManager = null;
    displayManager = null;
    displayProtocol = "wayland";
    defaultSession = null;
    windowShell = null;
    shell = null;
    shellPrompt = null;
    desktopShell = null;
    notificationDaemon = null;
    fileManager = null;
    terminal = null;
    appLauncher = null;
    bar = null;
  };

  loginManagers = {
    gdm = {
      support = ["wayland" "xorg"];
      type = "gui";
      base = "c";
      maturity = "stable";
      vibe = "gnome-first";
    };
    greetd = {
      support = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "rust";
      maturity = "stable";
      vibe = "minimal-unixy";
    };
    lemurs = {
      support = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "rust";
      maturity = "young";
      vibe = "tui-fancy";
    };
    lightdm = {
      support = ["wayland" "xorg"];
      type = "gui";
      base = "c";
      maturity = "legacy";
      vibe = "swiss-army";
    };
    ly = {
      support = ["wayland" "xorg" "tty"];
      type = "tui";
      base = "zig";
      maturity = "niche";
      vibe = "aesthetic-min";
    };
    sddm = {
      support = ["wayland" "xorg"];
      type = "gui";
      base = "cpp";
      maturity = "stable";
      vibe = "qt-kde";
    };
  };

  desktopEnvironments = {
    gnome =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland" "xorg"];
        preferredProtocol = "wayland";
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

    plasma =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland" "xorg"];
        preferredProtocol = "wayland";
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

    cosmic =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
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

    pantheon =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

    cinnamon =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

    xfce =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

  windowManagers = {
    hyprland =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["sddm" "gdm" "greetd" "lemurs" "ly"];
          preferred = "sddm";
        };
        desktopShell = "hyprland";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        appLauncher = "wofi";
      };

    niri =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["dms-greeter" "sddm" "gdm" "greetd" "lemurs" "ly"];
          preferred = "dms-greeter";
        };
        desktopShell = "niri";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "foot";
        appLauncher = "fuzzel";
      };

    sway =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["gdm" "sddm" "greetd" "lemurs" "ly"];
          preferred = "gdm";
        };
        desktopShell = "sway";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        appLauncher = "wofi";
      };

    river =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["sddm" "greetd" "lemurs" "ly"];
          preferred = "sddm";
        };
        desktopShell = "river";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        appLauncher = "fuzzel";
      };

    i3 =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
        displayManager = {
          supported = ["lightdm" "gdm" "sddm"];
          preferred = "lightdm";
        };
        desktopShell = "i3";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        appLauncher = "rofi";
      };

    bspwm =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
        displayManager = {
          supported = ["lightdm" "gdm" "sddm"];
          preferred = "lightdm";
        };
        desktopShell = "bspwm";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        appLauncher = "rofi";
      };

    qtile =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

    awesome =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

    xmonad =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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

    openbox =
      interfacePartsDefaults
      // {
        supportedProtocol = ["xorg"];
        preferredProtocol = "xorg";
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
    base = interfacePartsDefaults // interface;
    desktopEnvironment = base.desktopEnvironment;
    windowManager = base.windowManager;
    displayProtocolInput = base.displayProtocol;
    displayManagerInput = base.displayManager;
    desktopShellInput = base.desktopShell;
    notificationDaemonInput = base.notificationDaemon;
    fileManagerInput = base.fileManager;
    terminalInput = base.terminal;
    appLauncherInput = base.appLauncher;

    defaultDisplayProtocol = "wayland";
    defaultDisplayManager = "ly";

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

    displayProtocol =
      if selectedInterface != null
      then
        if displayProtocolInput != null && elem displayProtocolInput selectedInterface.config.supportedProtocol
        then displayProtocolInput
        else selectedInterface.config.preferredProtocol
      else if displayProtocolInput != null
      then displayProtocolInput
      else defaultDisplayProtocol;

    displayManager =
      if displayManagerInput != null
      then displayManagerInput
      else if selectedInterface != null
      then selectedInterface.config.displayManager.preferred
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
    interfacePartsDefaults
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
      interfaces = {inherit desktopEnvironments windowManagers loginManagers;};
    };
in {
  inherit
    mkUI
    loginManagers
    desktopEnvironments
    windowManagers
    normalizeInterface
    ;
}
