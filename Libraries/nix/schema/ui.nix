{_, ...}: let
  __exports = {
    internal = composites // functions;
    external = {
      mkUISchema = mkUI;
      mkUIDefault = mkDefault;
      mkUIOptions = mkOptions;
      normalizeUI = normalize;
    };
  };

  composites = {
    inherit
      defaults
      enums
      options
      registry
      ;
  };
  functions = {
    inherit
      mkUI
      normalize
      mkDefault
      mkOptions
      ;
  };

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.predicates) hasAttr isAttrs;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) optional toList;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.reduction) concatMap;
  inherit (_.lists.transformation) unique;
  inherit
    (_.options.construction)
    mkOptionEnum
    mkOptionEnums
    mkOption
    mkTrue
    ;
  inherit (_.schema) io;
  appSchema = _.schema.applications;
  inherit (_.schema.io) keyboardDefaults normalizeKeyboard;
  inherit (_.strings.construction) optionalString;
  inherit (_.types.combinators) submodule attrsOf;
  inherit (_.types.primitives) str anything;
  inherit (_.types.combinators) nullOr;
  registry = _.applications.filters.queries.interface;
  # sh = _.applications.shell;
  appEnums = _.applications.enums;
  iface = _.applications.filters.queries.interface;

  #|------------------------------------------------------|
  #| Data ------------------------------------------------|
  #|------------------------------------------------------|
  defaults = {
    inherit (io.defaults) keyboard;
    panel = null;
    notifier = null;
    desktopEnvironment = null;
    windowManager = null;
    greeter = null;
    protocol = null;
    session = null;
    compositor = {
      desktop = null;
      window = null;
    };
    shell = {
      system = "bash";
      interactive = "bash";
      prompt = "starship";
      lineEditor = "blesh";
      enhancements = [
        "atuin"
        "zoxide"
        "fzf"
      ];
    };
    apps = {
      inherit
        (appSchema.uiDefaults)
        launcher
        terminal
        explorer
        browser
        editor
        ;
    };
  };

  enums = {
    # Shell enums — toEnums already walked the shell filter tree.
    inherit (appEnums) shells;

    # Interface enums — toEnums walked the interface filter tree.
    # Each sub-key is either an Enum (leaf) or a nested attrset of Enums.
    greeters = appEnums.interface.greeters.all;
    protocols = appEnums.interface.protocols.all;
    panels = appEnums.interface.panels.all;
    notifiers = appEnums.interface.notifiers.all;

    environment = {
      # queries.forDesktop / forCompositor are registry attrsets → Enums.
      desktop = appEnums.interface.environments.queries.forDesktop;
      window = appEnums.interface.environments.queries.forCompositor;
    };

    compositors = {
      desktop = appEnums.interface.compositors.all;
      window = appEnums.interface.compositors.all;
    };
  };

  options = {
    enable = mkTrue "User Interface";
    registry = mkOption {
      description = "Detailed interface registry";
      default = registry;
      type = attrsOf (attrsOf anything);
    };
    environment = {
      desktop = mkOptionEnum {
        description = "Desktop Environment";
        default = defaults.desktopEnvironment;
        input = enums.environment.desktop.values;
      };
      window = mkOptionEnum {
        description = "Window Manager / Compositor";
        default = defaults.windowManager;
        input = enums.environment.window.values;
      };
    };

    desktopEnvironment = mkOptionEnum {
      description = "Desktop Environment";
      default = defaults.desktopEnvironment;
      input = enums.environment.desktop.values;
    };

    windowManager = mkOptionEnum {
      description = "Window Manager / Compositor";
      default = defaults.windowManager;
      input = enums.environment.window.values;
    };

    greeter = mkOptionEnum {
      description = "Display Manager";
      default = defaults.greeter;
      input = enums.greeters.values;
    };

    displayManager = mkOptionEnum {
      description = "Display Manager";
      default = defaults.greeter;
      input = enums.greeters.values;
    };

    protocol = mkOptionEnum {
      description = "Display Protocol";
      default = defaults.protocol;
      input = enums.protocols.values;
    };

    displayProtocol = mkOptionEnum {
      description = "Display Protocol";
      default = defaults.protocol;
      input = enums.protocols.values;
    };

    defaultSession = mkOption {
      description = "Default display manager session";
      default = defaults.session;
      type = nullOr str;
    };

    panel = mkOptionEnum {
      description = "Desktop panel/bar";
      default = defaults.panel;
      input = enums.panels.values;
    };

    notifier = mkOptionEnum {
      description = "Desktop notification daemon";
      default = defaults.notifier;
      input = enums.notifiers.values;
    };

    compositor = {
      desktop = mkOptionEnum {
        description = "Desktop shell compositor";
        default = defaults.compositor.desktop;
        input = enums.compositors.desktop.values;
      };
      window = mkOptionEnum {
        description = "Windowing compositor";
        default = defaults.compositor.window;
        input = enums.environment.window.values;
      };
    };

    shell = {
      system = mkOptionEnum {
        description = "System shell";
        default = defaults.shell.system;
        input = appEnums.shells.shells.all.values;
      };
      interactive = mkOptionEnum {
        description = "Interactive shell";
        default = defaults.shell.interactive;
        input = appEnums.shells.shells.all.values;
      };
      prompt = mkOptionEnum {
        description = "Shell prompt";
        default = defaults.shell.prompt;
        input = appEnums.shells.prompts.all.values;
      };
      lineEditor = mkOptionEnum {
        description = "Line editor / readline replacement";
        default = defaults.shell.lineEditor;
        input = appEnums.shells.lineEditors.all.values;
      };
      enhancements = mkOptionEnums {
        description = "Shell enhancements (history, navigation, fuzzy)";
        default = defaults.shell.enhancements;
        input = appEnums.shells.enhancements.all.values;
      };
    };

    keyboard = mkOption {
      description = "Keyboard config and bindings";
      default = defaults.keyboard;
      type = io.types.keyboard;
    };
    apps = let
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
    in {
      launcher = mkOption {
        description = "Default app launchers";
        default = {inherit (defaults.apps.launcher) pri sec;};
        type = app;
      };
      terminal = mkOption {
        description = "Default terminal applications";
        default = {inherit (defaults.apps.terminal) pri sec;};
        type = app;
      };
      explorer = mkOption {
        description = "Default explorer applications";
        default = {inherit (defaults.apps.explorer) pri sec;};
        type = app;
      };
      browser = mkOption {
        description = "Default browser applications";
        default = {inherit (defaults.apps.browser) pri sec;};
        type = app;
      };
      editor = mkOption {
        description = "Default editor applications";
        default = {inherit (defaults.apps.editor) pri sec;};
        type = app;
      };
    };
  };

  #|------------------------------------------------------|
  #| Display ---------------------------------------------|
  #|------------------------------------------------------|
  dmsByProtocol = genAttrs (attrNames iface.protocols.all) (
    protocol: attrNames (filterAttrs (_: g: elem protocol (g.protocol or [])) iface.greeters.all)
  );

  dmsFor = protocols: unique (concatMap (p: dmsByProtocol.${p} or []) protocols);

  #|------------------------------------------------------|
  #| Environment -----------------------------------------|
  #|------------------------------------------------------|
  mkEnv = args: let
    protocols = args.protocols or (toList args.protocol or []);
    protocol = args.protocol or (optionalString (args ? protocols) (head args.protocols));
  in
    {
      displayProtocol = {
        supported = protocols;
        preferred = protocol;
      };
      displayManager = {
        supported = dmsFor protocols;
        preferred = args.greeter or null;
      };
      defaultSession = args.session or null;
    }
    // (removeAttrs args [
      "display"
      "protocol"
      "protocols"
    ]);
  desktopEnvironments = {
    gnome = mkEnv {
      protocols = [
        "wayland"
        "xorg"
      ];
      greeter = "gdm";
      compositor = {
        desktop = "gnome-shell";
        window = "mutter";
      };
      panel = "gnome-shell";
      notifier = "gnome-shell";
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
      protocols = [
        "wayland"
        "xorg"
      ];
      compositor = {
        desktop = "plasmashell";
        window = "kwin";
      };
      greeter = "plasma-login-shell";
      panel = "plasmashell";
      notifier = "plasmashell";
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "krunner";
        terminal.pri = "konsole";
        explorer.pri = "dolphin";
        editor.sec = "kate";
      };
      keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
        close.action = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut 'Window Close'";
        lock.action = "qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock";
        logout.action = "qdbus org.kde.Shutdown /Shutdown logout";
        screenshot.action = "spectacle -f";
        screenshotRegion.action = "spectacle -r";
        screenshotWindow.action = "spectacle -a";
      };
    };
    cosmic = mkEnv {
      protocol = "wayland";
      greeter = "cosmic-greeter";
      compositor = {
        desktop = "gnome-shell";
        window = "cosmic-comp";
      };
      panel = "cosmic-panel";
      notifier = "cosmic-notifications";
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "cosmic-launcher";
        terminal.pri = "cosmic-terminal";
        explorer.pri = "cosmic-files";
        editor.sec = "cosmic-text-editor";
      };
      keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
        close.action = "cosmic-comp-msg action close";
        lock.action = "cosmic-session-ctl lock";
        logout.action = "cosmic-session-ctl logout";
      };
    };
    pantheon = mkEnv {
      protocol = "xorg";
      greeter = "lightdm";
      compositor = {
        desktop = "gala";
        window = "gala";
      };
      panel = "wingpanel";
      notifier = "notification-daemon";
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "slingshot";
        terminal.pri = "pantheon-terminal";
        explorer.pri = "pantheon-files";
        editor.sec = "mousepad";
      };
      keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
        lock.action = "io.elementary.desktop.agent-polkit --lock";
      };
    };
    cinnamon = mkEnv {
      protocol = "xorg";
      greeter = "lightdm";
      compositor = {
        desktop = "cinnamon";
        window = "muffin";
      };
      panel = "cinnamon";
      notifier = "cinnamon";
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "cinnamon-menu";
        terminal.pri = "gnome-terminal";
        terminal.sec = "xfce4-terminal";
        explorer.pri = "nemo";
        editor.sec = "mousepad";
      };
      keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
        lock.action = "cinnamon-screensaver-command --lock";
        logout.action = "cinnamon-session-quit --logout --no-prompt";
      };
    };
    xfce = mkEnv {
      protocol = "xorg";
      greeter = "lightdm";
      compositor = {
        desktop = "xfce4-panel";
        window = "xfwm4";
      };
      panel = "xfce4-panel";
      notifier = "xfce4-notifyd";
      apps = recursiveUpdate defaults.apps {
        launcher.pri = "xfce4-appfinder";
        terminal.pri = "xfce4-terminal";
        explorer.pri = "thunar";
        editor.sec = "mousepad";
      };
      keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {
        lock.action = "xflock4";
        logout.action = "xfce4-session-logout --logout --fast";
      };
    };
  };
  windowManagers = let
    mkWayland = name:
      mkEnv {
        protocol = "wayland";
        greeter = "dms-greeter";
        compositor = {
          desktop = name;
          window = name;
        };
        panel = "dms-shell";
        notifier = null;
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
        protocol = "xorg";
        greeter = "regreet";
        compositor = {
          desktop = name;
          window = name;
        };
        panel = "polybar";
        notifier = "dunst";
        apps = recursiveUpdate defaults.apps {
          launcher.sec = "rofi";
          terminal.pri = "xfce4-terminal";
          explorer.pri = "thunar";
        };
        keyboard.bindings = recursiveUpdate defaults.keyboard.bindings {};
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
      panel = "qtile";
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
      panel = "awesome";
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
      panel = "xmobar";
      keyboard.bindings = {
        close.action = "xmonadctl kill";
        fullscreen.action = "xmonadctl full";
        logout.action = "xmonadctl quit";
        screenshot.action = "scrot";
        screenshotRegion.action = "scrot -s";
      };
    };
    openbox = recursiveUpdate (mkXorg "openbox") {
      panel = "tint2";
      notifier = "xfce4-notifyd";
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

  #|------------------------------------------------------|
  #| Resolution ------------------------------------------|
  #|------------------------------------------------------|
  keys = {
    selection = {
      desktopEnvironment = desktopEnvironments;
      windowManager = windowManagers;
    };
    resolution = [
      "apps"
      "compositor"
      "notifier"
      "panel"
    ];
  };
  select = {
    key,
    set,
    interface,
  }: let
    rawVal = interface.${key} or interface.session.${key} or null;
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

  #|------------------------------------------------------|
  #| Normalization ---------------------------------------|
  #|------------------------------------------------------|
  resolve = {
    key,
    interface,
    configs,
  }:
    interface.${key} or configs.wm.${key} or configs.de.${key} or defaults.${key};
  normalize = interface: let
    inherit
      (genAttrs (attrNames keys.selection) (
        n:
          select {
            inherit interface;
            key = n;
            set = keys.selection.${n};
          }
      ))
      desktopEnvironment
      windowManager
      ;

    configs = {
      de = desktopEnvironment.config;
      wm = windowManager.config;
    };

    environment =
      if windowManager.name != null
      then windowManager
      else if desktopEnvironment.name != null
      then desktopEnvironment
      else let
        env = interface.session.environment or defaults.windowManager or defaults.desktopEnvironment;
      in
        optionalAttrs (env != null) (
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
          }
        );

    enabled =
      (optional (desktopEnvironment.name != null) desktopEnvironment.name)
      ++ (optional (windowManager.name != null) windowManager.name);

    greeter =
      interface.session.greeter or interface.display.greeter or environment.config.displayManager.preferred
          or defaults.greeter;

    protocol =
      interface.display.protocol or interface.session.protocol or environment.config.displayProtocol.preferred
          or defaults.protocol;

    # session =
    #   interface.defaultSession or interface.session or configs.wm.defaultSession or configs.de.defaultSession
    #       or windowManager.name or desktopEnvironment.name or defaults.session;
    session = let
      fromInterface = interface.defaultSession or (interface.session or null);
      fromWm = configs.wm.defaultSession or (configs.de.defaultSession or null);
      fromEnv =
        if windowManager.name != null
        then windowManager.name
        else if desktopEnvironment.name != null
        then desktopEnvironment.name
        else null;
    in
      if fromInterface != null
      then fromInterface
      else if fromWm != null
      then fromWm
      else if fromEnv != null
      then fromEnv
      else defaults.session;

    shell = {
      system = interface.shell.system or interface.shell.login or defaults.shell.system;
      interactive = interface.shell.interactive or interface.shell.login or defaults.shell.interactive;
      prompt = interface.shell.prompt or defaults.shell.prompt;
      lineEditor = interface.shell.lineEditor or defaults.shell.lineEditor;
      enhancements = interface.shell.enhancements or defaults.shell.enhancements;
    };

    #? Merge order: io defaults → DE overrides → WM overrides → user overrides
    #? normalizeKeyboard converts all mod lists to strings at the boundary
    keyboard = normalizeKeyboard (
      recursiveUpdate (recursiveUpdate (recursiveUpdate keyboardDefaults (configs.de.keyboard or {})) (
        configs.wm.keyboard or {}
      )) (interface.keyboard or {})
    );
  in
    composites
    // {
      inherit
        enabled
        keyboard
        shell
        session
        ;
      defaultSession = session;
      desktopEnvironment = desktopEnvironment.name;
      windowManager = windowManager.name;
      displayManager = greeter;
      displayProtocol = protocol;
      enable = enabled != [];
    }
    // (genAttrs keys.resolution (key: resolve {inherit key interface configs;}));

  mkUI = {
    user ? {},
    host,
  }:
    normalize (recursiveUpdate (host.interface or {}) (user.interface or {}));

  requireUI = {
    host ? null,
    ui ? null,
  }:
    assert host != null || ui != null;
      if ui != null
      then ui
      else mkUI {inherit host;};

  mkDefault = args: let
    resolvedUI = requireUI args;
    go = opt: val:
      if opt ? type || opt ? description
      then
        if val != null
        then opt // {default = val;}
        else opt
      else
        genAttrs (attrNames opt) (subkey:
          go opt.${subkey} (
            if isAttrs val
            then val.${subkey} or null
            else null
          ));
  in
    key: go resolvedUI.options.${key} (resolvedUI.${key} or null);

  mkOptions = args: let
    withDefault = mkDefault args;
  in
    listToAttrs (
      map (key: {
        name = key;
        value = withDefault key;
      }) (attrNames options)
    );
in
  __exports.internal // {__rootAliases = __exports.external;}
