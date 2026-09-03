{
  config,
  lix,
  host,
  ...
}: let
  inherit
    (lix.modules.construction)
    mkConfig
    mkContext
    mkIf
    mkMerge
    ;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) enum nullOr;
  inherit (lix.types.primitives) int str;

  context = mkContext {
    inherit config;
    dom = "interface";
    # sub = "common";
    mod = "session";
  };
  inherit (context) cfg ctx;

  user = host.users.primary or {};
in
  mkConfig {
    inherit context;
    options = {
      protocol = mkOption {
        description = "Target display server protocol for the interface.";
        type = enum [
          "wayland"
          "x11"
        ];
        default = "wayland";
      };

      defaultSession = mkOption {
        description = "Default session name passed to the display manager (e.g. hyprland, gnome, cosmic).";
        type = nullOr str;
        default = ctx.wm or ctx.de or null;
        defaultText = literalExpression "ctx.wm or ctx.de or null";
      };

      autologin = {
        enable = mkEnable {
          description = "Whether to enable automatic login for the primary user.";
          condition = user.autoLogin or false;
          defaultText = literalExpression "host.users.primary.autoLogin or false";
        };
        user = mkOption {
          description = "Username for automatic login. Defaults to the primary user's name.";
          default = user.name or null;
          defaultText = literalExpression "host.users.primary.name or null";
          example = literalExpression ''"craole"'';
          type = nullOr str;
        };
        delay = mkOption {
          description = "Seconds of inactivity after which autologin occurs.";
          default = 0;
          type = int;
        };
        relogin = mkEnable {
          description = "Whether to automatically re-login after logout (SDDM).";
          condition = false;
        };
      };
    };

    outputs = {
      environment.sessionVariables = mkMerge [
        {
          XDG_SESSION_TYPE = cfg.protocol;
        }
        (mkIf (cfg.protocol == "wayland") {
          NIXOS_OZONE_WL = "1";
          WLR_RENDERER_ALLOW_SOFTWARE = "1";
          WLR_NO_HARDWARE_CURSORS = "1";

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
        })
      ];

      services.displayManager = {
        defaultSession = mkIf (cfg.defaultSession != null) cfg.defaultSession;

        autoLogin = {
          enable = cfg.autologin.enable;
          user = cfg.autologin.user;
        };

        gdm.autoLogin.delay = mkIf (config.services.displayManager.gdm.enable or false) cfg.autologin.delay;

        sddm.autoLogin.relogin =
          mkIf (
            config.services.displayManager.sddm.enable or false
          )
          cfg.autologin.relogin;
      };
    };
  }
