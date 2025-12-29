{
  lib,
  lix,
  user,
  ...
}: let
  app = "plasma";
  opt = [app "kde" "plasma6"];

  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;

  isAllowed = isIn opt [(user.desktopEnvironment or null)];
in {
  config = mkIf isAllowed {
    programs = {
      ${app} =
        {enable = true;}
        // import ./settings.nix;
    };
  };
}
