{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  enriched = {
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
    uiShell = null;
    notificationDaemon = null;
    fileManager = null;
    terminal = null;
    launcher = null;
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
        uiShell = "gnome-shell";
        notificationDaemon = "gnome-shell";
        fileManager = "nautilus";
        terminal = "gnome-terminal";
        launcher = "gnome-shell-overview";
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
        uiShell = "plasmashell";
        notificationDaemon = "plasmashell";
        fileManager = "dolphin";
        terminal = "konsole";
        launcher = "krunner";
      };

    cosmic =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["gdm" "greetd" "lemurs" "sddm" "ly"];
          preferred = "gdm";
        };
        uiShell = "cosmic-shell";
        notificationDaemon = "cosmic-notifications";
        fileManager = "cosmic-files";
        terminal = "cosmic-terminal";
        launcher = "cosmic-launcher";
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
        uiShell = "gala";
        notificationDaemon = "notification-daemon";
        fileManager = "pantheon-files";
        terminal = "pantheon-terminal";
        launcher = "slingshot";
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
        uiShell = "cinnamon";
        notificationDaemon = "cinnamon";
        fileManager = "nemo";
        terminal = "gnome-terminal";
        launcher = "cinnamon-menu";
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
        uiShell = "xfce4-panel";
        notificationDaemon = "xfce4-notifyd";
        fileManager = "thunar";
        terminal = "xfce4-terminal";
        launcher = "xfce4-appfinder";
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
        uiShell = "hyprland";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "wofi";
      };

    niri =
      interfacePartsDefaults
      // {
        supportedProtocol = ["wayland"];
        preferredProtocol = "wayland";
        displayManager = {
          supported = ["sddm" "gdm" "greetd" "lemurs" "ly"];
          preferred = "sddm";
        };
        uiShell = "niri";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "fuzzel";
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
        uiShell = "sway";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "wofi";
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
        uiShell = "river";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "fuzzel";
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
        uiShell = "i3";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "rofi";
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
        uiShell = "bspwm";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "rofi";
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
        uiShell = "qtile";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "rofi";
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
        uiShell = "awesome";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "rofi";
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
        uiShell = "xmonad";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "alacritty";
        launcher = "rofi";
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
        uiShell = "openbox";
        notificationDaemon = "xfce4-notifyd";
        fileManager = "thunar";
        terminal = "xfce4-terminal";
        launcher = "rofi";
      };
  };

  normalizeInterface = interface: let
    desktopEnvironment = interface.desktopEnvironment    or null;
    windowManager = interface.windowManager         or null;
    displayProtocolInput = interface.displayProtocol       or null;
    displayManagerInput = interface.displayManager        or null;
    uiShellInput = interface.uiShell               or null;
    notificationDaemonInput = interface.notificationDaemon    or null;
    fileManagerInput = interface.fileManager           or null;
    terminalInput = interface.terminal              or null;
    launcherInput = interface.launcher              or null;

    defaultDisplayProtocol = "wayland";
    defaultDisplayManager = "ly";

    selectedInterface =
      if
        desktopEnvironment
        != null
        && builtins.hasAttr desktopEnvironment desktopEnvironments
      then {
        name = desktopEnvironment;
        kind = "desktopEnvironment";
        config = desktopEnvironments.${desktopEnvironment};
      }
      else if
        windowManager
        != null
        && builtins.hasAttr windowManager windowManagers
      then {
        name = windowManager;
        kind = "windowManager";
        config = windowManagers.${windowManager};
      }
      else null;

    updated = {
      displayProtocol =
        if selectedInterface != null
        then
          if
            displayProtocolInput
            != null
            && builtins.elem displayProtocolInput
            selectedInterface.config.supportedProtocol
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

      uiShell =
        if uiShellInput != null
        then uiShellInput
        else if selectedInterface != null
        then selectedInterface.config.uiShell
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

      launcher =
        if launcherInput != null
        then launcherInput
        else if selectedInterface != null
        then selectedInterface.config.launcher
        else null;
    };
  in
    interface
    // updated
    // {
      interfaces = {
        inherit desktopEnvironments windowManagers loginManagers;
      };
    };
in {
  inherit
    enriched
    loginManagers
    desktopEnvironments
    windowManagers
    normalizeInterface
    ;
}
