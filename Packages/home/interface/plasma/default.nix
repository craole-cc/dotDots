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

  packages = import ./packages.nix {inherit pkgs;};
in {
  # Add an assertion instead
  assertions = lib.optional isAllowed {
    assertion = config.programs ? ${app};
    message = "Plasma desktop environment requested but plasma-manager is not imported. Add it to your flake inputs and home-manager imports.";
  };

  config = mkIf isAllowed {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./bindings)
      (import ./modules {inherit src pkgs config nixosConfig;})
    ];

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/Packages/home/interface/plasma/dump.nix";
      };
      inherit packages;
    };
  };
}
