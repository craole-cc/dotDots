{
  config,
  lix,
  host,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "media";
    mod = "freetube";
  };
  isAllowed = isIn "video" (host.functionalities or []);
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.programs.freetube =
      {
        enable = true;
      }
      // import ./settings.nix;
  }
