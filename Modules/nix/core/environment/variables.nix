{
  config,
  host,
  lib,
  lix,
  inputs,
  pkgs,
  top,
  tree,
  ...
}: let
  dom = "environment";
  mod = "variables";
  cfg = config.${top}.${dom}.${mod};
  inherit (host.paths) dots;
  user = host.users.data.primary or {};
  apps = user.applications or {};
  inherit (pkgs.stdenv.hostPlatform) system;
  wallpapers = host.paths.wallpapers or tree.local.res.wallpapers;

  inherit (config.${top}.interface) displayProtocol;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrsOf str;
  inherit
    (lix.applications.resolution)
    editors
    browsers
    terminals
    launchers
    bars
    ;

  registry = let
    editor = editors.commands {
      inherit pkgs system inputs;
      cfg = apps.editor or {};
    };
    browser = browsers.commands {
      inherit pkgs system inputs;
      cfg = apps.browser or {};
    };
    terminal = terminals.commands {
      inherit pkgs system inputs;
      cfg = apps.terminal or {};
    };
    launcher = launchers.commands {
      inherit pkgs system inputs;
      cfg = apps.launcher or {};
    };
    bar = bars.commands {
      inherit pkgs system inputs;
      cfg = apps.bar or {};
    };

    default =
      {
        BAR = bar.primary;
        BROWSER = browser.primary;
        DOTS = dots;
        EDITOR = editor.editor;
        LAUNCHER = launcher.primary;
        TERMINAL = terminal.primary;
        VISUAL = editor.visual;
        WALLPAPERS = wallpapers;
      }
      // optionalAttrs (displayProtocol == "wayland") {
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
        # _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.xrender=true";
        #   -Dawt.useSystemAAFontSettings=on: enable antialiasing
        #   -Dswing.aatext=true: enable anti-aliased text
        #   -Dsun.java2d.xrender=true: enable XRender extension for Java2D
      };
  in {
    inherit editor browser terminal launcher bar default;
    all = default // editor // browser // terminal // launcher // bar;
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
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

  config = mkIf cfg.enable {
    environment.sessionVariables = cfg.default // cfg.extra;
  };
}
