{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "core";
    mod = "nushell";
  };
  isAllowed = isIn "nushell" ((user.shells or []) ++ (user.applications.allowed or []));
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = isAllowed;
    };
    outputs = {
      programs.nushell = mkMerge [
        {enable = true;}
        # (import ./plugins.nix {inherit pkgs;})
        (import ./settings.nix)
      ];
      home.packages = with pkgs; [
        nufmt
        nu_scripts
      ];
    };
  }
