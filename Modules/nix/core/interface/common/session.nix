{
  config,
  lix,
  host,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "common";
    mod = "session";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) enum int str;

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
      environment.sessionVariables = {
        XDG_SESSION_TYPE = cfg.protocol;
      };

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
