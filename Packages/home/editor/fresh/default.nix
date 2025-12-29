{
  pkgs,
  lib,
  user,
  lix,
  inputs,
  system,
  ...
}: let
  app = "fresh";
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lix.lists.predicates) isIn;

  # system = pkgs.stdenv.hostPlatform.system;

  isPrimary = app == user.applications.editor.tty.primary or null;
  isSecondary = app == user.applications.editor.tty.secondary or null;
  isAllowed =
    (isIn app (user.applications.allowed or []))
    || isPrimary
    || isSecondary;

  #> Use Fresh Editor from inputs if available
  freshPackage = inputs.packages.fresh-editor.${system}.default or null;
in {
  config = mkIf (isAllowed && freshPackage != null) {
    home = {
      packages = [freshPackage];
      sessionVariables =
        optionalAttrs isPrimary {EDITOR = app;}
        // optionalAttrs isSecondary {EDITOR_ALT = app;};
    };
  };
}
