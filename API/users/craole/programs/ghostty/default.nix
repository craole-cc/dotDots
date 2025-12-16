{
  lib,
  user,
  ...
}: let
  app = "ghostty";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem;
  inherit (user) enable;
  inherit (user.applications.terminal) primary secondary;
  isPrimary = app == primary;
  isSecondary = app == secondary;
  isAllowed = elem app enable || isPrimary || isSecondary;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./settings.nix
    ./themes.nix
  ];
  home.sessionVariables =
    {}
    // optionalAttrs isPrimary {TERMINAL = app;}
    // optionalAttrs isSecondary {TERMINAL_ALT = app;};
}
