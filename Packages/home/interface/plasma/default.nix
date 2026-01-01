{
  lib,
  lix,
  user,
  config,
  pkgs,
  src,
  ...
}: let
  app = "plasma";
  opt = [app "kde" "plasma6"];

  inherit (lib.modules) mkIf;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn (user.interface.desktopEnvironment or null) opt;
  isAvailable = config?programs.${app};
in {
  config = mkIf (isAllowed && isAvailable) {
    programs = {
      ${app} =
        {enable = true;}
        // import ./bindings
        // import ./files
        // import ./modules/input.nix
        // import ./modules/launcher.nix
        // import ./modules/power.nix
        // import ./modules/session.nix {inherit src;}
        // import ./modules/windows.nix
        // import ./modules/workspace.nix {inherit pkgs;};
    };

    home.packages = with pkgs.kdePackages; [
      koi
      krohnkite
      yakuake
    ];
  };
}
