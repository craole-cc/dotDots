{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.${dom};

  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkOption;
  inherit (lib.types) bool nullOr str;
  inherit (lix.modules.core.services) mkServices;

  # Pure data seed - only used in option defaults, never in config block.
  # All other interface options (windowManager, displayManager, shell.*, etc.)
  # are already declared by options.nix via mkOptions { inherit host; }.
  user = host.users.data.primary or {};
in {
  options.${top}.${dom} = {
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

  config = mkIf cfg.enable (
    mkServices {
      inherit config;
      inherit
        (cfg)
        windowManager
        desktopEnvironment
        displayProtocol
        displayManager
        defaultSession
        panel
        autoLogin
        autoLoginUser
        ;
    }
  );
}
