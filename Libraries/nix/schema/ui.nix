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
    toList
    optional
    unique
    ;
  inherit (lib.strings) optionalString;
  inherit (_.lists.generators) mkEnum;
  inherit (_.schema.io) keyboardDefaults normalizeKeyboard;
  inherit (_.schema) io;
  inherit (_.options) mkOption;
  inherit (_.types) submodule nullOr str;
  sh = _.applications.shells;

  __exports = {
    internal =
      composites
      // {
        inherit
          mkUI
          defaults
          normalize
          ;
      };
    external = {
      mkUISchema = mkUI;
      normalizeUISchema = normalize;
    };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Data                                                      ║
  #╚═══════════════════════════════════════════════════════════╝

  composites = {
    #~@ Sets
    inherit
      desktopEnvironments
      windowManagers
      displayManagers
      displayProtocols
      ;

    shells = {
      system = sh.system;
      interactive = sh.interactive;
    };

    #~@ Enums/Lists
    enums = {
      shells = {
        system = sh.enums.system;
        interactive = sh.enums.interactive;
      };

      desktopEnvironments = mkEnum {
        values = desktopEnvironments;
        nullable = true;
      };
      windowManagers = mkEnum {
        values = windowManagers;
        nullable = true;
      };
      displayManagers = mkEnum displayManagers;
      displayProtocols = mkEnum {
        values = displayProtocols;
        nullable = true;
      };
    };

    #~@ Types
    types = rec {
      inherit (io.types) keyboard;

      gui = submodule {
        options = {
          desktop = mkOption {
            type = nullOr str;
            default = null;
          };
          window = mkOption {
            type = nullOr str;
            default = null;
          };
          bar = mkOption {
            type = nullOr str;
            default = null;
          };
          notification = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      };

      app = submodule {
        options = {
          pri = mkOption {
            type = nullOr str;
            default = null;
          };
          sec = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      };

      apps = submodule {
        options = {
          launcher = mkOption {type = app;};
          terminal = mkOption {type = app;};
          explorer = mkOption {type = app;};
          browser = mkOption {type = app;};
          editor = mkOption {type = app;};
        };
      };
    };
  };

  defaults = {
    inherit (io.defaults) keyboard;
    apps = {
      launcher = {
        pri = "vicinae";
        sec = "vicinae";
      };
      terminal = {
        pri = "kitty";
        sec = "ghostty";
      };
      explorer = {
        pri = "doublecmd";
        sec = "yazi";
      };
      browser = {
        pri = "zen-twilight";
        sec = "chromium";
      };
      editor = {
        pri = "vscode";
        sec = "helix";
      };
    };

    gui = {
      desktop = null;
      window = null;
      bar = null;
      notification = null;
    };

    session = {
      desktopEnvironment = null;
      windowManager = null;
      manager = null;
      protocol = null;
      trigger = null;
    };

    shell = {
      system = "bash";
      interactive = "bash";
      prompt = "starship";
    };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Display                                                   ║
  #╚═══════════════════════════════════════════════════════════╝
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

  displayProtocols = [
    "tty"
    "wayland"
    "xorg"
  ];

  dmsByProtocol = genAttrs displayProtocols (protocol:
    attrNames
    (
      filterAttrs (_: displayManager:
        elem protocol displayManager.supported)
      displayManagers
    ));

  dmsFor = protocols:
    unique (
      concatMap
      (protocol: dmsByProtocol.${protocol} or [])
      protocols
    );

  #╔═══════════════════════════════════════════════════════════╗
  #║ Environment                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  mkEnv = {session, ...} @ args: let
    dp =
      if session ? protocol
      then toList session.protocol
      else if session ? protocols
      then toList session.protocols
      else [];
  in
    {
      displayProtocol = {
        supported = dp;
        preferred = optionalString (dp != []) (head dp);
      };
      displayManager = {
        supported = dmsFor dp;
        preferred = session.manager or null;
      };
      defaultSession = session.trigger or null;
    }
    // (removeAttrs args ["display"]);

  desktopEnvironments = {
    gnome = mkEnv {
      session = {
        protocols = ["wayland" "xorg"];
        manager = "gdm";
      };
      gui = {
        desktop = "gnome-shell";
        window = "mutter";
        bar = "gnome-shell";
        notification = "gnome-shell";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "gnome-shell-overview";
        terminal.pri = "gnome-terminal";
        explorer.pri = "nautilus";
        editor.sec = "gedit";
      };
      keyboard.bindings = {
        close.action = "dbus-send --type=method_call --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval string:'global.display.get_focus_window().delete(global.get_current_time());'";
        lock.action = "dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock";
        logout.action = "gnome-session-quit --logout --no-prompt";
        screenshot.action = "gnome-screenshot";
        screenshotRegion.action = "gnome-screenshot -a";
        screenshotWindow.action = "gnome-screenshot -w";
      };
    };

    plasma = mkEnv {
      session = {
        protocols = ["wayland" "xorg"];
        protocol = "wayland";
        manager = "sddm";
      };
      gui = {
        desktop = "plasmashell";
        window = "kwin";
        bar = "plasmashell";
        notification = "plasmashell";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "krunner";
        terminal.pri = "konsole";
        explorer.pri = "dolphin";
        editor.sec = "kate";
      };
      keyboard.bindings = {
        close.action = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut 'Window Close'";
        lock.action = "qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock";
        logout.action = "qdbus org.kde.Shutdown /Shutdown logout";
        screenshot.action = "spectacle -f";
        screenshotRegion.action = "spectacle -r";
        screenshotWindow.action = "spectacle -a";
      };
    };

    cosmic = mkEnv {
      session = {
        protocols = ["wayland" "xorg"];
        manager = "cosmic-greeter";
      };
      gui = {
        desktop = "cosmic-shell";
        window = "cosmic-comp";
        bar = "cosmic-panel";
        notification = "cosmic-notifications";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "cosmic-launcher";
        terminal.pri = "cosmic-terminal";
        explorer.pri = "cosmic-files";
        editor.sec = "cosmic-text-editor";
      };
      keyboard.bindings = {
        close.action = "cosmic-comp-msg action close";
        lock.action = "cosmic-session-ctl lock";
        logout.action = "cosmic-session-ctl logout";
      };
    };

    pantheon = mkEnv {
      session = {
        protocol = "xorg";
        manager = "lightdm";
      };
      gui = {
        desktop = "gala";
        window = "gala";
        bar = "wingpanel";
        notification = "notification-daemon";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "slingshot";
        terminal.pri = "pantheon-terminal";
        explorer.pri = "pantheon-files";
        editor.sec = "mousepad";
      };
      keyboard.bindings = {
        lock.action = "io.elementary.desktop.agent-polkit --lock";
      };
    };

    cinnamon = mkEnv {
      session = {
        protocol = "xorg";
        manager = "lightdm";
      };
      gui = {
        desktop = "cinnamon";
        window = "muffin";
        bar = "cinnamon";
        notification = "cinnamon";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "cinnamon-menu";
        terminal.pri = "gnome-terminal";
        terminal.sec = "xfce4-terminal";
        explorer.pri = "nemo";
        editor.sec = "mousepad";
      };
      keyboard.bindings = {
        lock.action = "cinnamon-screensaver-command --lock";
        logout.action = "cinnamon-session-quit --logout --no-prompt";
      };
    };

    xfce = mkEnv {
      session = {
        protocol = "xorg";
        manager = "lightdm";
      };
      gui = {
        desktop = "xfce4-panel";
        window = "xfwm4";
        bar = "xfce4-panel";
        notification = "xfce4-notifyd";
      };
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "xfce4-appfinder";
        terminal.pri = "xfce4-terminal";
        explorer.pri = "thunar";
        editor.sec = "mousepad";
      };
      keyboard.bindings = {
        lock.action = "xflock4";
        logout.action = "xfce4-session-logout --logout --fast";
      };
    };
  };

  windowManagers = let
    mkWayland = name:
      mkEnv {
        session = {
          protocol = "wayland";
          manager = "dms-greeter";
          trigger = name;
        };
        gui = {
          desktop = name;
          window = name;
          bar = "dms-shell";
          notification = "dms-shell";
        };
        apps = recursiveUpdate defaults.apps {
          launcher.sec = "dms-shell";
          terminal.pri = "foot";
        };
        keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
          lock.action = "dms ipc call lock lock";
          screenshot.action = "dms ipc call niri screenshotScreen";
          screenshotRegion.action = "dms ipc call niri screenshot";
          screenshotWindow.action = "dms ipc call niri screenshotWindow";
          launcher.action = "dms ipc call spotlight toggle";
          clipboard.action = "dms ipc call clipboard toggle";
          notifications.action = "dms ipc call notifications toggle";
          controlCenter.action = "dms ipc call control-center toggle";
          powerMenu.action = "dms ipc call powermenu toggle";
          taskManager.action = "dms ipc call processlist toggle";
          nightMode.action = "dms ipc call night toggle";
          doNotDisturb.action = "dms ipc call notifications toggleDoNotDisturb";
          dash.action = "dms ipc call dash toggle overview";
        };
      };

    mkXorg = name:
      mkEnv {
        session = {
          protocol = "xorg";
          manager = "regreet";
          trigger = name;
        };
        gui = {
          desktop = name;
          window = name;
          bar = "polybar";
          notification = "dunst";
        };
        apps = recursiveUpdate defaults.apps {
          launcher.sec = "rofi";
          terminal.pri = "xfce4-terminal";
          explorer.pri = "thunar";
        };
      };
  in {
    hyprland = recursiveUpdate (mkWayland "hyprland") {
      keyboard.bindings = {
        overview.action = "dms ipc call hypr toggleOverview";
        workspaceRename.action = "dms ipc call workspace-rename open";
        keybinds.action = "dms ipc call keybinds toggle hyprland";
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
        logout.action = "hyprctl dispatch exit";
        screenshot.action = "hyprshot -m output";
        screenshotRegion.action = "hyprshot -m region";
        screenshotWindow.action = "hyprshot -m window";
      };
    };
    niri = recursiveUpdate (mkWayland "niri") {
      keyboard.bindings = {
        workspaceRename.action = "dms ipc call workspace-rename open";
        keybinds.action = "dms ipc call keybinds toggle niri";
        close.action = "niri msg action close-window";
        fullscreen.action = "niri msg action fullscreen-window";
        maximize.action = "niri msg action maximize-column";
        float.action = "niri msg action toggle-window-floating";
        workspacePrev.action = "niri msg action focus-workspace-previous";
        windowCycle.action = "niri msg action focus-window-previous";
        logout.action = "niri msg action quit";
        screenshot.action = "grim";
        screenshotRegion.action = "grim -g \"$(slurp)\"";
        screenshotWindow.action = "grim -g \"$(slurp -w 0)\"";
      };
    };

    sway = recursiveUpdate (mkWayland "sway") {
      keyboard.bindings = {
        keybinds.action = "dms ipc call keybinds toggle sway";
        close.action = "swaymsg kill";
        fullscreen.action = "swaymsg fullscreen toggle";
        maximize.action = "swaymsg fullscreen toggle";
        float.action = "swaymsg floating toggle";
        pin.action = "swaymsg sticky toggle";
        split.action = "swaymsg split toggle";
        workspacePrev.action = "swaymsg workspace back_and_forth";
        windowCycle.action = "swaymsg focus next";
        # lock.action = "swaylock";
        logout.action = "swaymsg exit";
        screenshot.action = "grim";
        screenshotRegion.action = "grim -g \"$(slurp)\"";
        screenshotWindow.action = "grim -g \"$(slurp -w 0)\"";
      };
    };

    river = recursiveUpdate (mkWayland "river") {
      keyboard.bindings = {
        close.action = "riverctl close";
        fullscreen.action = "riverctl toggle-fullscreen";
        float.action = "riverctl toggle-float";
        workspacePrev.action = "riverctl focus-previous-tags";
        # lock.action = "swaylock";
        logout.action = "riverctl exit";
        screenshot.action = "grim";
        screenshotRegion.action = "grim -g \"$(slurp)\"";
      };
    };

    i3 = recursiveUpdate (mkXorg "i3") {
      keyboard.bindings = {
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

    bspwm = recursiveUpdate (mkXorg "bspwm") {
      keyboard.bindings = {
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

    qtile = recursiveUpdate (mkXorg "qtile") {
      gui.bar = "qtile";
      keyboard.bindings = {
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

    awesome = recursiveUpdate (mkXorg "awesome") {
      gui.bar = "awesome";
      keyboard.bindings = {
        close.action = "awesome-client 'client.focus:kill()'";
        fullscreen.action = "awesome-client 'client.focus.fullscreen = not client.focus.fullscreen; client.focus:raise()'";
        float.action = "awesome-client 'client.focus.floating = not client.focus.floating'";
        workspacePrev.action = "awesome-client 'awful.tag.history.restore()'";
        logout.action = "awesome-client 'awesome.quit()'";
        screenshot.action = "scrot";
        screenshotRegion.action = "scrot -s";
      };
    };

    xmonad = recursiveUpdate (mkXorg "xmonad") {
      gui.bar = "xmobar";
      keyboard.bindings = {
        close.action = "xmonadctl kill";
        fullscreen.action = "xmonadctl full";
        logout.action = "xmonadctl quit";
        screenshot.action = "scrot";
        screenshotRegion.action = "scrot -s";
      };
    };

    openbox = recursiveUpdate (mkXorg "openbox") {
      gui = {
        bar = "tint2";
        notification = "xfce4-notifyd";
      };
      apps = {
        launcher.pri = "rofi";
        terminal.pri = "xfce4-terminal";
        explorer.pri = "pcmanfm";
        browser.sec = "chromium";
        editor.pri = "mousepad";
      };
      keyboard.bindings = {
        close.action = "openbox-msg close";
        fullscreen.action = "openbox-msg fullscreen";
        float.action = "openbox-msg undecorate toggle";
        logout.action = "openbox --exit";
        screenshot.action = "scrot";
        screenshotRegion.action = "scrot -s";
      };
    };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Resolution                                                ║
  #╚═══════════════════════════════════════════════════════════╝

  keys = {
    selection = {
      desktopEnvironment = desktopEnvironments;
      windowManager = windowManagers;
    };
    resolution = [
      "apps"
      "gui"
    ];
  };

  select = {
    key,
    set,
    interface,
  }: let
    rawVal =
      interface.${key} 
      or interface.session.${key}
      or defaults.session.${key};
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
      name = null;
      kind = key;
      config = {};
    }
    else throw "Unknown ${key}: ${name}.";

  #╔═══════════════════════════════════════════════════════════╗
  #║ Normalization                                             ║
  #╚═══════════════════════════════════════════════════════════╝
  resolve = {
    key,
    interface,
    configs,
  }:
    interface.${key}
      or configs.wm.${key}
      or configs.de.${key}
      or defaults.${key};

  normalize = interface: let
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
        else if desktopEnvironment.name != null
        then desktopEnvironment
        else let
          env =
            interface.session.environment
            or defaults.session.environment;
        in
          if hasAttr env windowManagers
          then {
            name = env;
            kind = "windowManager";
            config = windowManagers.${env};
          }
          else {
            name = env;
            kind = "desktopEnvironment";
            config = desktopEnvironments.${env};
          };

      manager =
        interface.session.manager
        or interface.display.manager
        or sessions.environment.displayManager.preferred
        or defaults.session.manager;

      protocol =
        interface.display.protocol
        or interface.session.protocol
        or configs.wm.displayProtocol.preferred
        or configs.de.displayProtocol.preferred
        or defaults.session.protocol;

      trigger =
        interface.session
        or configs.wm.defaultSession  
        or configs.de.defaultSession  
        or windowManager.name         
        or desktopEnvironment.name    
        or defaults.session.trigger;

      enabled =
        (optional (desktopEnvironment.name != null) desktopEnvironment.name)
        ++ (optional (windowManager.name != null) windowManager.name);

      default =
        interface.defaultSession
        or configs.wm.defaultSession
        or configs.de.defaultSession
        or windowManager.name
        or desktopEnvironment.name
        or defaults.session.trigger;
    };

    shell = {
      system =
        interface.shell.system or
        interface.shell.login or
        defaults.shell.system;
      interactive =
        interface.shell.interactive or
        defaults.shell.interactive;
      prompt = interface.shell.prompt or defaults.shell.prompt;
    };
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
  in
    {
      inherit defaults keyboard sessions shell composites;
      desktopEnvironment = desktopEnvironment.name;
      windowManager = windowManager.name;
      displayManager = sessions.manager;
      displayProtocol = sessions.protocol;
      defaultSession = sessions.default;
    }
    // (genAttrs keys.resolution (key:
      resolve {
        inherit
          key
          interface
          configs
          ;
      }));

  mkUI = {
    user ? {},
    host,
  }:
    normalize (
      recursiveUpdate
      (host.interface or {})
      (user.interface or {})
    );
in
  __exports.internal // {_rootAliases = __exports.external;}
