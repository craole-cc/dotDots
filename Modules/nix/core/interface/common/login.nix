{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.resolved.${dom};

  inherit (lib.options) literalExpression mkOption;
  inherit (lib.types) bool nullOr str;
  inherit (lix.modules.core.services) mkServices;

  user = host.users.data.primary or {};
  sessionArgs = {
    inherit config;
    inherit
      (cfg)
      windowManager
      desktopEnvironment
      displayProtocol
      displayManager
      defaultSession
      panel
      compositor
      autoLogin
      autoLoginUser
      ;
  };
  payload = mkServices sessionArgs;
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.${dom} = {
    autoLogin = mkOption {
      description = "Whether to enable automatic login for the primary user.";
      default = user.autoLogin or false;
      defaultText = literalExpression "host.users.data.primary.autoLogin or false";
      type = bool;
    };
    autoLoginUser = mkOption {
      description = "Username for automatic login. Defaults to the primary user's name.";
      default = user.name or null;
      defaultText = literalExpression "host.users.data.primary.name or null";
      example = literalExpression ''"craole"'';
      type = nullOr str;
    };
  };

  config = lib.mkMerge (mkStaged {
    condition = cfg.enable;
    inherit top payload;
  });
}
