{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.inputs.${dom};

  inherit (lib.options) literalExpression mkOption;
  inherit (lib.types) bool nullOr str;
  inherit (lix.modules.core.services) mkServices;
  inherit (lix.modules.core._) mkStaged;

  user = host.users.data.primary or {};
  sessionArgs = {
    inherit config;
    inherit (cfg)
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
in {
  options.${top}.inputs.${dom} = {
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
