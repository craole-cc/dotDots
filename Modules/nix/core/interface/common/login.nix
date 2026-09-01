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
    mod = "login";
  };
  inherit (context) cfg;
  inherit (lix.options.construction) literalExpression mkOption mkEnable;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) int str;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  user = host.users.primary or {};
in
  mkConfig {
    inherit context;
    options = {
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
          description = "Seconds of inactivity after which the autologin will be performed.";
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
      services = {
        displayManager = {
          autoLogin = {
            enable = cfg.autologin.enable;
            user = cfg.autologin.user;
          };

          # GDM-specific delay
          gdm.autoLogin.delay =
            mkIf config.services.displayManager.gdm.enable cfg.autologin.delay;

          # SDDM-specific relogin
          sddm.autoLogin.relogin =
            mkIf config.services.displayManager.sddm.enable cfg.autologin.relogin;
        };
      };
    };
  }
