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
    mod = "zsh";
  };
  isAllowed = isIn "zsh" ((user.shells or []) ++ (user.applications.allowed or []));
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.programs.zsh =
      {
        enable = true;
      }
      // import ./settings.nix;
  }
