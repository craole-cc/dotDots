{
  lib,
  lix,
  user,
  ...
}: let
  app = "helix";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lix.lists.predicates) isIn;

  isPrimary = app == user.applications.editor.tty.primary or null;
  isSecondary = app == user.applications.editor.tty.secondary or null;
  isAllowed =
    (isIn app (user.applications.allowed or []))
    || isPrimary
    || isSecondary;
in {
  programs.${app} =
    {enable = isAllowed;}
    // import ./editor.nix
    // import ./keybindings.nix
    // import ./languages.nix
    // import ./themes.nix;

  home.sessionVariables =
    optionalAttrs isPrimary {EDITOR = "hx";}
    // optionalAttrs isSecondary {EDITOR_ALT = "hx";};
}
