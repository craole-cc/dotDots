{lib, ...}: let
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    genAttrs
    hasAttr
    optionalAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) concatMap elem head optional unique;

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
    in {
      modifier = mod;
      swapCapsEscape = true;
      #? Base keyboard actions that can be overridden
      terminal = {
        inherit mod;
        key = "RETURN";
        action = "$TERMINAL";
      };
      terminalSec = {
        mod = mod ++ ["SHIFT"];
        key = "RETURN";
        action = "$TERMINAL_SEC";
      };
      visual = {
        inherit mod;
        key = "V";
        action = "$VISUAL";
      };
      visualSec = {
        mod = mod ++ ["SHIFT"];
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
        mod = mod ++ ["SHIFT"];
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
        mod = mod ++ ["CTRL"];
        key = "L";
        action = "loginctl terminate-session self";
      };
      sleep = {
        mod = mod ++ ["CTRL"];
        key = "S";
        action = "systemctl suspend";
      };
      reboot = {
        mod = mod ++ ["CTRL"];
        key = "R";
        action = "systemctl reboot";
      };
      reboot_soft = {
        mod = mod ++ ["CTRL" "SHIFT"];
        key = "R";
        action = "systemctl soft-reboot";
      };
      shutdown = {
        mod = mod ++ ["CTRL"];
        key = "Q";
        action = "systemctl poweroff";
      };
    };
  };

  displayManagers = {
    cosmic-greeter = {
      supported = ["wayland"];
      type = "gui";
      base = "rust";
      maturity = "young";
      vibe = "cosmic-native";
    };
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
    regreet = {
      supported = ["wayland" "xorg"];
      type = "gui";
      base = "rust";
      maturity = "stable";
      vibe = "clean-gtk";
    };
    sddm = {
      supported = ["wayland" "xorg"];
      type = "gui";
      base = "cpp";
      maturity = "stable";
      vibe = "qt-kde";
    };
    tuigreet = {
      supported = ["wayland" "tty"];
      type = "tui";
      base = "rust";
      maturity = "stable";
      vibe = "minimal-industrial";
    };
  };

  #> Pre-calculate DMs by protocol for faster lookup
  dmsByProtocol = genAttrs ["wayland" "xorg" "tty"] (
    p:
      attrNames (
        filterAttrs
        (_: dm: elem p dm.supported)
        displayManagers
      )
  );

  dmsFor = protocols:
    unique (
      concatMap
      (p: dmsByProtocol.${p} or [])
      protocols
    );

  mkEnv = {
    protocols,
    preferredDM,
    ...
  } @ args:
    {
      displayProtocol = {
        supported = protocols;
        preferred = head protocols;
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = preferredDM;
      };
    }
    // (removeAttrs args ["protocols" "preferredDM"]);

  desktopEnvironments = {
    gnome = mkEnv {
      protocols = ["wayland" "xorg"];
      preferredDM = "gdm";
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
    plasma = mkEnv {
      protocols = ["wayland" "xorg"];
      preferredDM = "sddm";
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
    cosmic = mkEnv {
      protocols = ["wayland"];
      preferredDM = "cosmic-greeter";
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
    pantheon = mkEnv {
      protocols = ["xorg"];
      preferredDM = "lightdm";
      desktopShell = "gala";
      windowShell = "gala";
      bar = "wingpanel";
      notificationDaemon = "notification-daemon";
      fileManager = "pantheon-files";
      terminal = "pantheon-terminal";
      appLauncher = "slingshot";
      keyboard.lock.action = "io.elementary.desktop.agent-polkit --lock";
    };
    cinnamon = mkEnv {
      protocols = ["xorg"];
      preferredDM = "lightdm";
      desktopShell = "cinnamon";
      windowShell = "muffin";
      bar = "cinnamon";
      notificationDaemon = "cinnamon";
      fileManager = "nemo";
      terminal = "gnome-terminal";
      appLauncher = "cinnamon-menu";
      keyboard = {
        lock.action = "cinnamon-screensaver-command --lock";
        logout.action = "cinnamon-session-quit --logout --no-prompt";
      };
    };
    xfce = mkEnv {
      protocols = ["xorg"];
      preferredDM = "lightdm";
      desktopShell = "xfce4-panel";
      windowShell = "xfwm4";
      bar = "xfce4-panel";
      notificationDaemon = "xfce4-notifyd";
      fileManager = "thunar";
      terminal = "xfce4-terminal";
      appLauncher = "xfce4-appfinder";
      keyboard = {
        lock.action = "xflock4";
        logout.action = "xfce4-session-logout --logout --fast";
      };
    };
  };

  windowManagers = let
    waylandBase = name:
      mkEnv {
        protocols = ["wayland"];
        preferredDM = "greetd";
        bar = "waybar";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = "kitty";
        appLauncher = "vicinae";
        desktopShell = name;
        defaultSession = name;
      };
    xorgBase = name:
      mkEnv {
        protocols = ["xorg"];
        preferredDM = "lightdm";
        bar = "polybar";
        notificationDaemon = "dunst";
        fileManager = "thunar";
        terminal = "xterm";
        appLauncher = "rofi";
        desktopShell = name;
        defaultSession = name;
      };
  in {
    hyprland =
      (waylandBase "hyprland")
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
      (waylandBase "niri")
      // {
        keyboard = {
          close.action = "niri msg action close-window";
          logout.action = "niri msg action quit";
        };
      };
    sway =
      (waylandBase "sway")
      // {
        keyboard = {
          close.action = "swaymsg kill";
          lock.action = "swaylock";
          logout.action = "swaymsg exit";
        };
      };
    river =
      (waylandBase "river")
      // {
        keyboard = {
          close.action = "riverctl close";
          logout.action = "riverctl exit";
        };
      };
    i3 =
      (xorgBase "i3")
      // {
        keyboard = {
          close.action = "i3-msg kill";
          lock.action = "i3lock";
          logout.action = "i3-msg exit";
        };
      };
    bspwm =
      (xorgBase "bspwm")
      // {
        keyboard = {
          close.action = "bspc node -c";
          logout.action = "bspc quit";
        };
      };
    qtile =
      (xorgBase "qtile")
      // {
        bar = "qtile";
        keyboard = {
          close.action = "qtile-cmd -o window -f kill";
          logout.action = "qtile-cmd -o cmd -f shutdown";
        };
      };
    awesome =
      (xorgBase "awesome")
      // {
        bar = "awesome";
        keyboard = {
          close.action = "awesome-client 'client.focus:kill()'";
          logout.action = "awesome-client 'awesome.quit()'";
        };
      };
    xmonad =
      (xorgBase "xmonad")
      // {
        bar = "xmobar";
        keyboard.close.action = "xmonadctl kill";
      };
    openbox =
      (xorgBase "openbox")
      // {
        bar = "tint2";
        notificationDaemon = "xfce4-notifyd";
        terminal = "xfce4-terminal";
        keyboard.logout.action = "openbox --exit";
      };
  };

  keys = {
    #? Selection: Keys that pick an object from a predefined set
    selection = {
      desktopEnvironment = desktopEnvironments;
      windowManager = windowManagers;
    };

    #? Validation: Keys that must check against a "supported" list
    validation = ["displayProtocol" "displayManager"];

    #> Standardization: Keys that follow the simple User > WM > DE > Default chain
    resolution = [
      "appLauncher"
      "bar"
      "desktopShell"
      "fileManager"
      "notificationDaemon"
      "shell"
      "shellPrompt"
      "terminal"
      "windowShell"
    ];
  };

  #? { name = string|null; config = set; }
  select = {
    key,
    set,
    interface,
  }: let
    kind = key;
    name = interface.${kind} or defaults.${kind};
  in
    if name != null && hasAttr name set
    then {
      inherit name kind;
      config = set.${name};
    }
    else if name == null
    then {
      inherit name kind;
      config = {}; #? Safe fallback
    }
    else throw "Unknown ${kind}: ${name}.";

  normalizeInterface = interface: let
    #> Resolve the core selections first (de/wm) because everything else depends on them
    inherit
      (genAttrs (attrNames keys.selection) (
        n:
          select {
            key = n;
            set = keys.selection.${n};
            inherit interface;
          }
      ))
      desktopEnvironment
      windowManager
      ;

    #> Safe Configs: Grouped to prevent null-reference crashes
    configs = {
      de = desktopEnvironment.config;
      wm = windowManager.config;
    };

    sessions = {
      #? The primary Window Manager or Desktop Environmntr (WM prioritized)
      environment =
        if windowManager.name != null
        then windowManager
        else desktopEnvironment;

      #? The primary displayManager (DE prioritized)
      manager =
        interface.displayManager or
        configs.de.displayManager.preferred or
        configs.wm.displayManager.preferred or
        defaults.displayManager;

      enabled =
        (
          optional
          (desktopEnvironment.name != null)
          desktopEnvironment.name
        )
        ++ (
          optional
          (windowManager.name != null)
          windowManager.name
        );

      #? Primary startup session string (e.g., "hyprland-uwsm")
      #? (User Explicit > WM Specific > DE Specific > WM Name > DE Name)
      default =
        interface.defaultSession or
        configs.wm.defaultSession or
        configs.de.defaultSession or
        windowManager.name or
        desktopEnvironment.name or
        null;
    };

    #> Multi-tier lookup: prefer User Inputs > WM > DE > Defaults
    resolve = key:
      interface.${key} or
      configs.wm.${key} or
      configs.de.${key} or
      defaults.${key};

    validate = key: let
      required =
        if key == "displayManager"
        then sessions.manager
        else resolve key;
      supported = unique (
        (configs.de.${key}.supported or [])
        ++ (configs.wm.${key}.supported or [])
        ++ [defaults.${key}]
      );
      fallback =
        configs.wm.${key}.preferred or
        configs.de.${key}.preferred or
        defaults.${key};
    in
      if elem required supported
      then required
      else fallback;

    composites = {
      inherit sessions;
      defaultSession = sessions.default;
      interfaces = {
        inherit desktopEnvironments windowManagers displayManagers;
      };

      keyboard =
        recursiveUpdate (
          recursiveUpdate (
            recursiveUpdate
            defaults.keyboard
            (configs.de.keyboard or {})
          )
          (configs.wm.keyboard or {})
        )
        (interface.keyboard or {});
    };
  in
    {inherit desktopEnvironment windowManager;}
    // composites
    // (genAttrs keys.resolution resolve)
    // (genAttrs keys.validation validate);

  mkUI = {
    user,
    host,
  }:
    normalizeInterface (
      recursiveUpdate
      (host.interface or {})
      (user.interface or {})
    );
in
  __exports.internal // {_rootAliases = __exports.external;}
