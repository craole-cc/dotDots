{lib, ...}: let
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    hasAttr
    optionalAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) any elem;

  defaults = {
    appLauncher = null;
    bar = null;
    defaultSession = null;
    desktopEnvironment = null;
    desktopShell = null;
    displayManager = null;
    displayProtocol = null;
    fileManager = "yazi";
    notificationDaemon = null;
    shell = "bash";
    shellPrompt = "starship";
    terminal = "ghostty";
    windowManager = "hyprland";
    windowShell = null;
    keyboard = let
      mod = ["SUPER"];
      modShift = mod ++ ["SHIFT"];
      modCtrl = mod ++ ["CTRL"];
      modCtrlShift = mod ++ ["CTRL" "SHIFT"];
    in {
      modifier = mod;
      swapCapsEscape = true;
      terminal = {
        inherit mod;
        key = "RETURN";
        action = "$TERMINAL";
      };
      terminalSec = {
        mod = modShift;
        key = "RETURN";
        action = "$TERMINAL_SEC";
      };
      visual = {
        inherit mod;
        key = "V";
        action = "$VISUAL";
      };
      visualSec = {
        mod = modShift;
        key = "V";
        action = "$VISUAL_SEC";
      };
      fileManager = {
        inherit mod;
        key = "F";
        action = "$FILE_MANAGER";
      };
      browser = {
        inherit mod;
        key = "B";
        action = "$BROWSER";
      };
      browserSec = {
        mod = modShift;
        key = "B";
        action = "$BROWSER_SEC";
      };
      close = {
        inherit mod;
        key = "Q";
        action = "wmctrl -c :ACTIVE:";
      };
      lock = {
        inherit mod;
        key = "L";
        action = "loginctl lock-session";
      };
      logout = {
        mod = modCtrl;
        key = "L";
        action = "loginctl terminate-session self";
      };
      sleep = {
        mod = modCtrl;
        key = "S";
        action = "systemctl suspend";
      };
      reboot = {
        mod = modCtrl;
        key = "R";
        action = "systemctl reboot";
      };
      reboot_soft = {
        mod = modCtrlShift;
        key = "R";
        action = "systemctl soft-reboot";
      };
      shutdown = {
        mod = modCtrl;
        key = "Q";
        action = "systemctl poweroff";
      };
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

  dmsFor = protocols:
    attrNames (
      filterAttrs (
        _: dm: any (p: elem p dm.supported) protocols
      )
      displayManagers
    );

  desktopEnvironments = {
    gnome = let
      protocols = ["wayland" "xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "wayland";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "gdm";
      };
      desktopShell = "gnome-shell";
      windowShell = "mutter";
      bar = "gnome-shell";
      notificationDaemon = "gnome-shell";
      fileManager = "nautilus";
      terminal = "gnome-terminal";
      appLauncher = "gnome-shell-overview";
      keyboard = {
        close.action = "dbus-send --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.display.get_focus_window().delete(global.get_current_time());'";
        lock.action = "dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock";
        logout.action = "gnome-session-quit --logout --no-prompt";
      };
    };

    plasma = let
      protocols = ["wayland" "xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "wayland";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "sddm";
      };
      desktopShell = "plasmashell";
      windowShell = "kwin";
      bar = "plasmashell";
      notificationDaemon = "plasmashell";
      fileManager = "dolphin";
      terminal = "konsole";
      appLauncher = "krunner";
      keyboard = {
        close.action = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut 'Window Close'";
        lock.action = "qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock";
        logout.action = "qdbus org.kde.Shutdown /Shutdown logout";
      };
    };

    cosmic = let
      protocols = ["wayland"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "wayland";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "cosmic-greeter";
      };
      desktopShell = "cosmic-shell";
      windowShell = "cosmic-comp";
      bar = "cosmic-panel";
      notificationDaemon = "cosmic-notifications";
      fileManager = "cosmic-files";
      terminal = "cosmic-terminal";
      appLauncher = "cosmic-launcher";
      keyboard = {
        close.action = "cosmic-comp-msg action close";
        lock.action = "cosmic-session-ctl lock";
        logout.action = "cosmic-session-ctl logout";
      };
    };

    pantheon = let
      protocols = ["xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "xorg";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "lightdm";
      };
      desktopShell = "gala";
      windowShell = "gala";
      bar = "wingpanel";
      notificationDaemon = "notification-daemon";
      fileManager = "pantheon-files";
      terminal = "pantheon-terminal";
      appLauncher = "slingshot";
      keyboard = {
        close.action = "wmctrl -c :ACTIVE:";
        lock.action = "io.elementary.desktop.agent-polkit --lock";
      };
    };

    cinnamon = let
      protocols = ["xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "xorg";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "lightdm";
      };
      desktopShell = "cinnamon";
      windowShell = "muffin";
      bar = "cinnamon";
      notificationDaemon = "cinnamon";
      fileManager = "nemo";
      terminal = "gnome-terminal";
      appLauncher = "cinnamon-menu";
      keyboard = {
        close.action = "wmctrl -c :ACTIVE:";
        lock.action = "cinnamon-screensaver-command --lock";
        logout.action = "cinnamon-session-quit --logout --no-prompt";
      };
    };

    xfce = let
      protocols = ["xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "xorg";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "lightdm";
      };
      desktopShell = "xfce4-panel";
      windowShell = "xfwm4";
      bar = "xfce4-panel";
      notificationDaemon = "xfce4-notifyd";
      fileManager = "thunar";
      terminal = "xfce4-terminal";
      appLauncher = "xfce4-appfinder";
      keyboard = {
        close.action = "wmctrl -c :ACTIVE:";
        lock.action = "xflock4";
        logout.action = "xfce4-session-logout --logout --fast";
      };
    };
  };
  windowManagers = let
    forWayland = name: let
      protocols = ["wayland"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "wayland";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "greetd";
      };
      bar = "waybar";
      windowShell = null;
      notificationDaemon = "mako";
      fileManager = "thunar";
      terminal = "kitty";
      appLauncher = "vicinae";
      desktopShell = name;
      defaultSession = name;
    };

    forXorg = name: let
      protocols = ["xorg"];
    in {
      displayProtocol = {
        supported = protocols;
        preferred = "xorg";
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = "lightdm";
      };
      bar = "polybar";
      windowShell = null;
      notificationDaemon = "dunst";
      fileManager = "thunar";
      terminal = "xterm";
      appLauncher = "rofi";
      desktopShell = name;
      defaultSession = name;
    };
  in {
    hyprland =
      forWayland "hyprland"
      // {
        defaultSession = "hyprland-uwsm";
        bar = "hyprpanel";
        windowShell = "quickshell";
        keyboard = {
          close.action = "hyprctl dispatch killactive";
          lock.action = "hyprlock";
          logout.action = "hyprctl dispatch exit";
        };
      };
    niri =
      forWayland "niri"
      // {
        keyboard = {
          close.action = "niri msg action close-window";
          # lock.action = "niri msg action activate-tracker-lock-screen";
          logout.action = "niri msg action quit";
        };
      };
    sway =
      forWayland "sway"
      // {
        keyboard = {
          close.action = "swaymsg kill";
          lock.action = "swaylock";
          logout.action = "swaymsg exit";
        };
      };
    river =
      forWayland "river"
      // {
        keyboard = {
          close.action = "riverctl close";
          logout.action = "riverctl exit";
        };
      };
    i3 =
      forXorg "i3"
      // {
        keyboard = {
          close.action = "i3-msg kill";
          lock.action = "i3lock";
          logout.action = "i3-msg exit";
        };
      };
    bspwm =
      forXorg "bspwm"
      // {
        keyboard = {
          close.action = "bspc node -c";
          logout.action = "bspc quit";
        };
      };
    qtile =
      forXorg "qtile"
      // {
        bar = "qtile";
        keyboard = {
          close.action = "qtile-cmd -o window -f kill";
          logout.action = "qtile-cmd -o cmd -f shutdown";
        };
      };
    awesome =
      forXorg "awesome"
      // {
        bar = "awesome";
        keyboard = {
          close.action = "awesome-client 'client.focus:kill()'";
          logout.action = "awesome-client 'awesome.quit()'";
        };
      };
    xmonad =
      forXorg "xmonad"
      // {
        bar = "xmobar";
        keyboard.close.action = "xmonadctl kill";
      };
    openbox =
      forXorg "openbox"
      // {
        bar = "tint2";
        notificationDaemon = "xfce4-notifyd";
        terminal = "xfce4-terminal";
        keyboard = {
          close.action = "wmctrl -c :ACTIVE:";
          logout.action = "openbox --exit";
        };
      };
  };

  getConfig = {
    name,
    attr,
    kind,
  }:
    if name == null
    then {}
    else if hasAttr name attr
    then attr.${name}
    else throw "Unknown ${kind}: ${name}. Available: ${toString (attrNames attr)}";

  normalizeInterface = interface: let
    _de = interface.desktopEnvironment or defaults.desktopEnvironment;
    _wm = interface.windowManager or defaults.windowManager;

    desktopEnvironment = let
      name = _de;
    in
      optionalAttrs
      (name != null && hasAttr name desktopEnvironments)
      {
        inherit name;
        kind = "desktopEnvironment";
        config = desktopEnvironments.${name};
      };

    windowManager = let
      name = _wm;
    in
      optionalAttrs
      (name != null && hasAttr name windowManagers)
      {
        inherit name;
        kind = "windowManager";
        config = windowManagers.${name};
      };

    configs = {
      de={}
    };
    config =
      recursiveUpdate
      (getConfig {
        inherit (desktopEnvironment) name kind;
        attr = desktopEnvironments;
      })
      (getConfig {
        inherit (windowManager) name kind;
        attr = windowManagers;
      });

    displayProtocol = let
      requested =
        interface.displayProtocol or
        config.displayProtocol.preferred or
        defaults.displayProtocol;
      supported =
        config.displayProtocol.supported or
        [requested];
      fallback =
        config.displayProtocol.preferred or
        defaults.displayProtocol;
    in
      if elem requested supported
      then requested
      else fallback;

    displayManager = let
      requested =
        interface.displayManager or
        config.displayManager.preferred or
        defaults.displayManager;
      supported =
        config.displayManager.supported or
        [requested];
      fallback =
        config.displayManager.preferred or
        defaults.displayManager;
    in
      if elem requested supported
      then requested
      else fallback;

    desktopShell =
      interface.desktopShell or
      config.desktopShell or
      defaults.desktopShell;

    windowShell =
      interface.windowShell or
      config.windowShell or
      defaults.windowShell;

    bar =
      interface.bar or
      config.bar or
      defaults.bar;

    notificationDaemon =
      interface.notificationDaemon or
      config.notificationDaemon or
      defaults.notificationDaemon;

    fileManager =
      interface.fileManager or
      config.fileManager or
      defaults.fileManager;

    terminal =
      interface.terminal or
      config.terminal or
      defaults.terminal;

    appLauncher =
      interface.appLauncher or
      config.appLauncher or
      defaults.appLauncher;

    shell =
      interface.shell or
      defaults.shell;

    shellPrompt =
      interface.shellPrompt or
      defaults.shellPrompt;

    defaultSession =
      interface.defaultSession or
      config.defaultSession or
      windowManager.name or
      desktopEnvironment.name or
      null;

    #> Merge Global Defaults <- Environment Specifics <- User Inputs
    keyboard = recursiveUpdate (
      recursiveUpdate
      defaults.keyboard
      (config.keyboard or {})
    ) (interface.keyboard or {});
  in {
    inherit
      desktopEnvironment
      windowManager
      displayProtocol
      displayManager
      desktopShell
      windowShell
      bar
      notificationDaemon
      fileManager
      terminal
      appLauncher
      shell
      shellPrompt
      keyboard
      defaultSession
      ;
    interfaces = {
      inherit
        desktopEnvironments
        windowManagers
        displayManagers
        ;
    };
  };

  mkUI = {
    user,
    host,
  }:
    normalizeInterface (
      recursiveUpdate
      (host.interface or {})
      (user.interface or {})
    );

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
in
  __exports.internal // {_rootAliases = __exports.external;}
