{
  _,
  lib,
  ...
}: let
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    genAttrs
    hasAttr
    isAttrs
    recursiveUpdate
    ;
  inherit
    (lib.lists)
    concatMap
    elem
    head
    optional
    unique
    ;

  inherit (_.schema.io) keyboardDefaults normalizeKeyboard;

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
  };

  displayManagers = {
    cosmic-greeter = {
      supported = ["wayland"];
      type = "gui";
      base = "rust";
      maturity = "young";
      vibe = "cosmic-native";
    };
    dms-greeter = {
      supported = ["wayland"];
      type = "gui";
      base = "rust";
      maturity = "young";
      vibe = "uwsm-native";
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
        screenshot.action = "gnome-screenshot";
        screenshotRegion.action = "gnome-screenshot -a";
        screenshotWindow.action = "gnome-screenshot -w";
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
        screenshot.action = "spectacle -f";
        screenshotRegion.action = "spectacle -r";
        screenshotWindow.action = "spectacle -a";
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
      keyboard = {
        lock.action = "io.elementary.desktop.agent-polkit --lock";
      };
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
    wayland = let
      apps = {
        bar = "waybar";
        notificationDaemon = "mako";
        fileManager = "thunar";
        terminal = {
          pri = "foot";
          sec = "ghostty";
        };
        editor = {
          pri = "code";
          sec = "zeditor";
        };
        appLauncher = "vicinae";
      };
      base = name:
        mkEnv {
          protocols = ["wayland"];
          inherit (apps) bar notificationDaemon fileManager appLauncher;
          preferredDM = "greetd";
          terminal = apps.terminal.pri;
          desktopShell = name;
          defaultSession = name;
        };
    in {inherit base apps;};

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
      (wayland.base "hyprland")
      // {
        defaultSession = "hyprland-uwsm";
        bar = "hyprpanel";
        windowShell = "quickshell";
        keyboard = let
          mkRunOrRaise = exec: ''
            bash -c 'cmd=$(basename "${exec}" | cut -d" " -f1); hyprctl dispatch focuswindow "class:^($cmd)$" || ${exec}'
          '';
        in
          with wayland.apps; {
            # --- Run or Raise using Variables ---
            browser.action = mkRunOrRaise "$BROWSER";
            fileManager.action = mkRunOrRaise "$FILE_MANAGER";
            # visual.action = mkRunOrRaise "$VISUAL";

            # Specific apps (if not using variables)
            visual.action = mkRunOrRaise visual.pri;
            visualSec.action = mkRunOrRaise visual.sec;
            terminal.action = mkRunOrRaise terminal.pri;
            terminalSec.action = mkRunOrRaise terminal.sec;

            # --- Standard Hyprland Dispatches ---
            close.action = "hyprctl dispatch killactive";
            fullscreen.action = "hyprctl dispatch fullscreen 0";
            maximize.action = "hyprctl dispatch fullscreen 1";
            float.action = "hyprctl dispatch togglefloating";
            pin.action = "hyprctl dispatch pin";
            split.action = "hyprctl dispatch togglesplit";
            pseudo.action = "hyprctl dispatch pseudo";
            groupToggle.action = "hyprctl dispatch togglegroup";
            groupLock.action = "hyprctl dispatch lockactivegroup toggle";
            workspacePrev.action = "hyprctl dispatch workspace previous";
            windowCycle.action = "hyprctl dispatch focuscurrentorlast";
            lock.action = "hyprlock";
            logout.action = "hyprctl dispatch exit";
            screenshot.action = "hyprshot -m output";
            screenshotRegion.action = "hyprshot -m region";
            screenshotWindow.action = "hyprshot -m window";
          };
      };

    niri =
      (wayland.base "niri")
      // {
        keyboard = {
          close.action = "niri msg action close-window";
          fullscreen.action = "niri msg action fullscreen-window";
          maximize.action = "niri msg action maximize-column";
          float.action = "niri msg action toggle-window-floating";
          workspacePrev.action = "niri msg action focus-workspace-previous";
          windowCycle.action = "niri msg action focus-window-previous";
          lock.action = "swaylock";
          logout.action = "niri msg action quit";
          screenshot.action = "grim";
          screenshotRegion.action = "grim -g \"$(slurp)\"";
          screenshotWindow.action = "grim -g \"$(slurp -w 0)\"";
        };
      };

    sway =
      (wayland.base "sway")
      // {
        keyboard = {
          close.action = "swaymsg kill";
          fullscreen.action = "swaymsg fullscreen toggle";
          maximize.action = "swaymsg fullscreen toggle";
          float.action = "swaymsg floating toggle";
          pin.action = "swaymsg sticky toggle";
          split.action = "swaymsg split toggle";
          workspacePrev.action = "swaymsg workspace back_and_forth";
          windowCycle.action = "swaymsg focus next";
          lock.action = "swaylock";
          logout.action = "swaymsg exit";
          screenshot.action = "grim";
          screenshotRegion.action = "grim -g \"$(slurp)\"";
          screenshotWindow.action = "grim -g \"$(slurp -w 0)\"";
        };
      };

    river =
      (wayland.base "river")
      // {
        keyboard = {
          close.action = "riverctl close";
          fullscreen.action = "riverctl toggle-fullscreen";
          float.action = "riverctl toggle-float";
          workspacePrev.action = "riverctl focus-previous-tags";
          lock.action = "swaylock";
          logout.action = "riverctl exit";
          screenshot.action = "grim";
          screenshotRegion.action = "grim -g \"$(slurp)\"";
        };
      };

    i3 =
      (xorgBase "i3")
      // {
        keyboard = {
          close.action = "i3-msg kill";
          fullscreen.action = "i3-msg fullscreen toggle";
          float.action = "i3-msg floating toggle";
          split.action = "i3-msg layout toggle split";
          workspacePrev.action = "i3-msg workspace back_and_forth";
          windowCycle.action = "i3-msg focus next";
          lock.action = "i3lock";
          logout.action = "i3-msg exit";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };

    bspwm =
      (xorgBase "bspwm")
      // {
        keyboard = {
          close.action = "bspc node -c";
          fullscreen.action = "bspc node -t fullscreen";
          float.action = "bspc node -t floating";
          pseudo.action = "bspc node -t pseudo_tiled";
          split.action = "bspc node -t tiled";
          workspacePrev.action = "bspc desktop -f last";
          lock.action = "betterlockscreen -l";
          logout.action = "bspc quit";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };

    qtile =
      (xorgBase "qtile")
      // {
        bar = "qtile";
        keyboard = {
          close.action = "qtile-cmd -o window -f kill";
          fullscreen.action = "qtile-cmd -o window -f toggle_fullscreen";
          float.action = "qtile-cmd -o window -f toggle_floating";
          workspacePrev.action = "qtile-cmd -o screen -f prev_group";
          windowCycle.action = "qtile-cmd -o screen -f next_group";
          logout.action = "qtile-cmd -o cmd -f shutdown";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };

    awesome =
      (xorgBase "awesome")
      // {
        bar = "awesome";
        keyboard = {
          close.action = "awesome-client 'client.focus:kill()'";
          fullscreen.action = "awesome-client 'client.focus.fullscreen = not client.focus.fullscreen; client.focus:raise()'";
          float.action = "awesome-client 'client.focus.floating = not client.focus.floating'";
          workspacePrev.action = "awesome-client 'awful.tag.history.restore()'";
          logout.action = "awesome-client 'awesome.quit()'";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };

    xmonad =
      (xorgBase "xmonad")
      // {
        bar = "xmobar";
        keyboard = {
          close.action = "xmonadctl kill";
          fullscreen.action = "xmonadctl full";
          logout.action = "xmonadctl quit";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };

    openbox =
      (xorgBase "openbox")
      // {
        bar = "tint2";
        notificationDaemon = "xfce4-notifyd";
        terminal = "xfce4-terminal";
        keyboard = {
          close.action = "openbox-msg close";
          fullscreen.action = "openbox-msg fullscreen";
          float.action = "openbox-msg undecorate toggle";
          logout.action = "openbox --exit";
          screenshot.action = "scrot";
          screenshotRegion.action = "scrot -s";
        };
      };
  };

  keys = {
    selection = {
      desktopEnvironment = desktopEnvironments;
      windowManager = windowManagers;
    };
    validation = ["displayProtocol" "displayManager"];
    resolution = ["appLauncher" "bar" "desktopShell" "fileManager" "notificationDaemon" "shell" "shellPrompt" "terminal" "windowShell"];
  };

  select = {
    key,
    set,
    interface,
  }: let
    rawVal = interface.${key} or defaults.${key};
    name =
      if isAttrs rawVal
      then rawVal.name or null
      else rawVal;
  in
    if name != null && hasAttr name set
    then {
      inherit name;
      kind = key;
      config = set.${name};
    }
    else if name == null
    then {
      inherit name;
      kind = key;
      config = {};
    }
    else throw "Unknown ${key}: ${name}.";

  normalizeInterface = interface: let
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

    configs = {
      de = desktopEnvironment.config;
      wm = windowManager.config;
    };

    sessions = {
      environment =
        if windowManager.name != null
        then windowManager
        else desktopEnvironment;

      manager =
        interface.displayManager
        or configs.de.displayManager.preferred
        or configs.wm.displayManager.preferred
        or defaults.displayManager;

      enabled =
        (optional (desktopEnvironment.name != null) desktopEnvironment.name)
        ++ (optional (windowManager.name != null) windowManager.name);

      default =
        interface.defaultSession
        or configs.wm.defaultSession
        or configs.de.defaultSession
        or windowManager.name
        or desktopEnvironment.name
        or null;
    };

    resolve = key:
      interface.${key}
      or configs.wm.${key}
      or configs.de.${key}
      or defaults.${key};

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
        configs.wm.${key}.preferred
        or configs.de.${key}.preferred
        or defaults.${key};
    in
      if elem required supported
      then required
      else fallback;

    composites = {
      inherit sessions;
      defaultSession = sessions.default;
      interfaces = {inherit desktopEnvironments windowManagers displayManagers;};

      #? Merge order: io defaults → DE overrides → WM overrides → user overrides
      #? normalizeKeyboard converts all mod lists to strings at the boundary
      keyboard = normalizeKeyboard (
        recursiveUpdate (
          recursiveUpdate (
            recursiveUpdate
            keyboardDefaults
            (configs.de.keyboard or {})
          )
          (configs.wm.keyboard or {})
        )
        (interface.keyboard or {})
      );
    };
  in
    {
      desktopEnvironment = desktopEnvironment.name;
      windowManager = windowManager.name;
    }
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
