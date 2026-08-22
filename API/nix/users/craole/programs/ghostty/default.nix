{
  lib,
  user,
  ...
}: let
  app = "ghostty";
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem;
  inherit (user.applications) allowed terminal;

  isPrimary = app == terminal.primary;
  isSecondary = app == terminal.secondary;
  isAllowed = elem app allowed || isPrimary || isSecondary;
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
