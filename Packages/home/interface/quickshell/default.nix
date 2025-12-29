{
  config,
  lib,
  user,
  ...
}: let
  app = "quickshell";
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  config = mkIf isAllowed {
    programs.${app} =
      {enable = true;}
      // import ./settings.nix;
  };
}
