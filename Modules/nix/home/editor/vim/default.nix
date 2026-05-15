{
  lib,
  lix,
  user,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;

  app = "vim";
  isPri = app == (user.applications.editor.tty.primary or null);
  isSec = app == (user.applications.editor.tty.secondary or null);
  isAllowed = isIn app (user.applications.allowed or []);
  enable = isPri || isSec || isAllowed;
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {inherit enable;}
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
