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
        # // import ./files
        // import ./modules {inherit src pkgs config;};
    };

    home.packages = with pkgs.kdePackages; [
      koi
      krohnkite
      yakuake
    ];
  };
}
