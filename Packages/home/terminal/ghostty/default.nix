{
  lib,
  lix,
  user,
  ...
}: let
  app = "ghostty";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lix.lists.predicates) isIn;
  inherit (lib.modules) mkIf;

  isPrimary = app == user.applications.terminal.primary or null;
  isSecondary = app == user.applications.terminal.secondary or null;
  isAllowed =
    (isIn app (user.applications.allowed or []))
    || isPrimary
    || isSecondary;
in {
  config = mkIf isAllowed {
    programs.${app} =
      {enable = isAllowed;}
      // import ./settings.nix
      // import ./themes.nix;

    home.sessionVariables =
      {}
      // optionalAttrs isPrimary {TERMINAL = app;}
      // optionalAttrs isSecondary {TERMINAL_ALT = app;};
  };
}
