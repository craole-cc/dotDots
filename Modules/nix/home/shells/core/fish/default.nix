{
  config,
  user,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "core";
    mod = "fish";
  };
  isAllowed = isIn "fish" ((user.shells or []) ++ (user.applications.allowed or []));
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.programs.fish =
      {
        enable = true;
      }
      // import ./settings.nix;
  }
