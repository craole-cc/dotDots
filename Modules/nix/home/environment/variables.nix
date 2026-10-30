{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "variables";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      default = mkOption {
        description = "Session variables from the user's API home paths";
        default = user.paths.variablesByRoot.home;
        type = attrsOf str;
      };
      extra = mkOption {
        description = "Additional user session variables";
        default = {};
        type = attrsOf str;
      };
    };
    outputs.home.sessionVariables = cfg.default // cfg.extra;
  }
