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
    mod = "bash";
  };
  isAllowed = isIn "bash" ((user.shells or []) ++ (user.applications.allowed or []));
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.programs.bash =
      {
        enable = true;
      }
      // import ./settings.nix;
  }
