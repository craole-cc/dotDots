{
  config,
  host,
  lib,
  lix,
  inputs,
  pkgs,
  top,
  ...
}: let
  dom = "environment";
  mod = "variables";
  cfg = config.${top}.${dom}.${mod};

  user = host.users.data.primary or {};
  apps = user.applications or {};
  system = pkgs.stdenv.hostPlatform.system;
  dp = config.${top}.interface.dp;

  dots = host.paths.dots or null;
  wallpapers = host.paths.wallpapers or null;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrsOf str;
  inherit (lix.applications.resolution) editors browsers terminals launchers bars;

  editorCmds = editors.commands {
    inherit pkgs system inputs;
    editorConfig = apps.editor or {};
  };
  browserCmds = browsers.commands {
    inherit pkgs system inputs;
    appConfig = apps.browser or {};
  };
  terminalCmds = terminals.commands {
    inherit pkgs system inputs;
    appConfig = apps.terminal or {};
  };
  launcherCmds = launchers.commands {
    inherit pkgs system inputs;
    appConfig = apps.launcher or {};
  };
  barCmds = bars.commands {
    inherit pkgs system inputs;
    appConfig = apps.bar or {};
  };

  defaultVars =
    {
      EDITOR = editorCmds.editor;
      VISUAL = editorCmds.visual;
      BROWSER = browserCmds.primary;
      TERMINAL = terminalCmds.primary;
      LAUNCHER = launcherCmds.primary;
      BAR = barCmds.primary;
    }
    // lib.optionalAttrs (dots != null) {DOTS = dots;}
    // lib.optionalAttrs (wallpapers != null) {WALLPAPERS = wallpapers;}
    // lib.optionalAttrs (dp == "wayland") {
      NIXOS_OZONE_WL = "1";
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";

      #~@ Firefox
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DBUS_REMOTE = "1"; #? Allows communication with gnome-shell
      MOZ_USE_XINPUT2 = "1"; #? Enables XInput2 extension

      #~@ Application Backend
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1"; #? Auto-detect screen scale factor
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
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    base = mkOption {
      description = "Base session variables";
      default = defaultVars;
      type = attrsOf str;
    };
    extra = mkOption {
      description = "Additional session variables";
      default = {};
      type = attrsOf str;
    };
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = cfg.base // cfg.extra;
  };
}
