{
  config,
  host,
  lix,
  inputs,
  pkgs,
  names,
  top,
  paths ? host.paths,
  ...
}:
let
  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "variables";
  };
  inherit (context) cfg;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lix.applications.resolution)
    editors
    browsers
    terminals
    launchers
    bars
    ;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.modules.construction) mkConfig mkContext mkDefault;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.transformation) toUpper;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;

  ice = config.${top}.resolved.interface;
  isWayland = ice.displayProtocol == "wayland";

  user = host.users.data.primary or { };
  apps = user.applications or { };
  wallpapers = host.paths.wallpapers or { };

  registry =
    let
      editor = editors.commands {
        inherit pkgs system inputs;
        config = apps.editor or { };
      };
      browser = browsers.commands {
        inherit pkgs system inputs;
        config = apps.browser or { };
      };
      terminal = terminals.commands {
        inherit pkgs system inputs;
        config = apps.terminal or { };
      };
      launcher = launchers.commands {
        inherit pkgs system inputs;
        config = apps.launcher or { };
      };
      bar = bars.commands {
        inherit pkgs system inputs;
        config = apps.bar or { };
      };

      default = {
        # The active interface panel is authoritative. The application registry
        # remains only as a fallback for hosts without an interface panel value.
        BAR = ice.panel or bar.primary;
        BROWSER = mkDefault browser.primary;
        "${toUpper names.src}" = paths.roots.repo;
        EDITOR = editor.editor;
        LAUNCHER = launcher.primary;
        TERMINAL = terminal.primary;
        VISUAL = editor.visual;
        WALLPAPERS = wallpapers;
      }
      // optionalAttrs isWayland {
        NIXOS_OZONE_WL = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";

        #~@ Firefox
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_DBUS_REMOTE = "1"; # ? Allows communication with gnome-shell
        MOZ_USE_XINPUT2 = "1"; # ? Enables XInput2 extension

        #~@ Application Backend
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # ? Auto-detect screen scale factor
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland";

        #~@ JAVA
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };
    in
    {
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
    enable = mkEnable { inherit context; };
    default = mkOption {
      description = "Base session variables";
      inherit (registry) default;
      type = attrsOf str;
    };
    extra = mkOption {
      description = "Additional session variables";
      default = { };
      type = attrsOf str;
    };
  };
  outputs = {
    environment.sessionVariables = cfg.default // cfg.extra;
  };
}
