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

  isPrimary = (user.applications.terminal.primary or null) == app;
  isSecondary = (user.applications.terminal.secondary or null) == app;
  isAllowed = (isIn app (user.applications.allowed or [])) || isPrimary || isSecondary;
in {
  config = mkIf true {
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
