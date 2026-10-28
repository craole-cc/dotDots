{
  config,
  host,
  lix,
  inputs,
  pkgs,
  names,
  paths ? host.paths,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "variables";
  };
  inherit (context) cfg;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit
    (lix.applications.resolution)
    editors
    browsers
    terminals
    launchers
    bars
    ;
  inherit (lix.applications.registry) resolve;

  inherit (lix.modules.construction) mkConfig mkContext mkDefault;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.transformation) toUpper;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;

  user = host.users.data.primary or {};
  groups = user.packages or (lix.schema.packages.resolve {record = user;});
  media = map (name: resolve {value = name; category = "media";}) (groups.media or []);
  mediaAt = index: if index < builtins.length media then builtins.elemAt media index else null;
  mediaCommand = index: let
    app = mediaAt index;
  in
    if app == null then null else app.exec or null;
  mediaName = index: let
    app = mediaAt index;
  in
    if app == null then null else app.name or null;
  wallpapers = host.paths.wallpapers or "$HOME/Pictures/Wallpapers";

  registry = let
    editor = editors.commands {
      inherit pkgs system inputs;
      config = {
        tty = groups.editor or {};
        gui = groups.ide or {};
      };
    };
    browser = browsers.commands {
      inherit pkgs system inputs;
      config = groups.browser or {};
    };
    terminal = terminals.commands {
      inherit pkgs system inputs;
      config = groups.terminal or {};
    };
    launcher = launchers.commands {
      inherit pkgs system inputs;
      config = groups.launcher or {};
    };
    bar = bars.commands {
      inherit pkgs system inputs;
      config = groups.bar or {};
    };

    default =
      filterAttrs (_name: value: value != null) {
        # The active interface panel is authoritative. The application registry
        # remains only as a fallback for hosts without an interface panel value.
        # TODO: move to interface/panels
        # BAR = ice.panel or bar.primary;
        "${toUpper names.src}" = paths.roots.repo;
        EDITOR = editor.editor;
        LAUNCHER = launcher.primary;
        TERMINAL = terminal.primary;
        VISUAL = editor.visual;
        WALLPAPERS = wallpapers;
      }
      // optionalAttrs (mediaCommand 0 != null) {
        MEDIA = mediaCommand 0;
        MEDIA_PRI = mediaCommand 0;
        MEDIA_PRI_NAME = mediaName 0;
        MEDIA_1 = mediaCommand 0;
        MEDIA_1_NAME = mediaName 0;
      }
      // optionalAttrs (mediaCommand 1 != null) {
        MEDIA_SEC = mediaCommand 1;
        MEDIA_SEC_NAME = mediaName 1;
        MEDIA_2 = mediaCommand 1;
        MEDIA_2_NAME = mediaName 1;
      }
      // optionalAttrs (mediaCommand 2 != null) {
        MEDIA_TER = mediaCommand 2;
        MEDIA_TER_NAME = mediaName 2;
        MEDIA_3 = mediaCommand 2;
        MEDIA_3_NAME = mediaName 2;
      }
      // optionalAttrs (browser.primary != null) {BROWSER = mkDefault browser.primary;};
    # TODO: Move to interface/session/protocol
    # // optionalAttrs isWayland {
    #   NIXOS_OZONE_WL = "1";
    #   WLR_RENDERER_ALLOW_SOFTWARE = "1";
    #   WLR_NO_HARDWARE_CURSORS = "1";
    #   XDG_SESSION_TYPE = "wayland";
    #   #~@ Firefox
    #   MOZ_ENABLE_WAYLAND = "1";
    #   MOZ_DBUS_REMOTE = "1"; # ? Allows communication with gnome-shell
    #   MOZ_USE_XINPUT2 = "1"; # ? Enables XInput2 extension
    #   #~@ Application Backend
    #   QT_QPA_PLATFORM = "wayland";
    #   QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    #   QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # ? Auto-detect screen scale factor
    #   SDL_VIDEODRIVER = "wayland";
    #   CLUTTER_BACKEND = "wayland";
    #   GDK_BACKEND = "wayland";
    #   #~@ JAVA
    #   _JAVA_AWT_WM_NONREPARENTING = "1";
    # };
  in {
    inherit
      editor
      browser
      terminal
      launcher
      bar
      default
      ;
    all = default // editor // browser // terminal // launcher // bar;
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      default = mkOption {
        description = "Base session variables";
        inherit (registry) default;
        type = attrsOf str;
      };
      extra = mkOption {
        description = "Additional session variables";
        default = {};
        type = attrsOf str;
      };
    };
    outputs = {
      environment.sessionVariables = cfg.default // cfg.extra;
    };
  }
