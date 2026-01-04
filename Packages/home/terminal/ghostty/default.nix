# {
#   lib,
#   lix,
#   user,
#   ...
# }: let
#   app = "ghostty";
#   inherit (lib.attrsets) optionalAttrs;
#   inherit (lix.lists.predicates) isIn;
#   inherit (lib.modules) mkIf;
#   isPrimary = (user.applications.terminal.primary or null) == app;
#   isSecondary = (user.applications.terminal.secondary or null) == app;
#   isAllowed = (isIn app (user.applications.allowed or [])) || isPrimary || isSecondary;
# in {
#   config = mkIf true {
#     programs.${app} =
#       {enable = isAllowed;}
#       # // import ./themes.nix
#       // import ./settings.nix;
#     home.sessionVariables =
#       {}
#       // optionalAttrs isPrimary {TERMINAL = app;}
#       // optionalAttrs isSecondary {TERMINAL_ALT = app;};
#   };
# }
{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "ghostty";
    kind = "terminal";
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./settings.nix)
      # (import ./input.nix)
      (import ./themes.nix)
    ];
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
