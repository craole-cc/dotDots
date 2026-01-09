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

  # Check if the option is defined by checking config._module.args or simply trying
  # This won't cause infinite recursion
  isAvailable = builtins.hasAttr app (config.programs or {});

  packages = import ./packages.nix {inherit pkgs;};
in
  lib.optionalAttrs (isAllowed && isAvailable) {
    programs.${app} = mkMerge [
      {enable = true;}
      (import ./bindings)
      # // import ./files
      (import ./modules {inherit src pkgs config nixosConfig;})
    ];

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/Packages/home/interface/plasma/dump.nix";
      };
      inherit packages;
    };
  }
