{
  # config,
  lib,
  user,
  ...
}: let
  app = "quickshell";
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf mkMerge;
  isAllowed = elem app (user.applications.allowed or []);
in {
  config = mkIf isAllowed {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./settings.nix)
    ];
  };
}
