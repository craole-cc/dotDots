{
  lib,
  lix,
  user,
  config,
  nixosConfig,
  pkgs,
  src,
  ...
}: let
  app = "plasma";
  opt = [app "kde" "plasma6"];

  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn (user.interface.desktopEnvironment or null) opt;
  isAvailable = config.programs?${app};

  packages = import ./packages.nix {inherit pkgs;};
in {
  config = mkIf (isAllowed && isAvailable) {
    programs = {
      ${app} = mkMerge [
        {enable = true;}
        (import ./bindings)
        # // import ./files
        (import ./modules {inherit src pkgs config nixosConfig;})
      ];
    };

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/Packages/home/interface/plasma/dump.nix";
      };
      inherit packages;
    };
  };
}
