{
  config,
  lib,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lib.modules) mkMerge;
  inherit (lix.lists.predicates) isIn;

  context = mkContext {
    inherit config;
    dom = "editor";
    mod = "vim";
    kind = "editor";
  };

  app = "vim";
  isPri = app == (user.applications.editor.tty.primary or null);
  isSec = app == (user.applications.editor.tty.secondary or null);
  isAllowed = isIn app (user.applications.allowed or []);
  enable = isPri || isSec || isAllowed;
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = enable;
    };
    outputs = {
      programs.${app} = mkMerge [
        {enable = true;}
        (import ./plugins.nix)
        (import ./settings.nix)
      ];

      home.sessionVariables =
        if isPri
        then {
          EDITOR_PRI = app;
          EDITOR_PRI_NAME = app;
        }
        else if isSec
        then {
          EDITOR_SEC = app;
          EDITOR_SEC_NAME = app;
        }
        else {};
    };
  }
