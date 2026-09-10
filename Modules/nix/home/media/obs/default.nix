{
  config,
  user,
  lib,
  lix,
  host,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "media";
    mod = "obs-studio";
  };
  isAllowed = isIn "video" (host.functionalities or []);
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs.programs.obs-studio =
      {
        enable = true;
      }
      // import ./plugins.nix {
        inherit
          pkgs
          lib
          lix
          user
          config
          ;
      };
  }
