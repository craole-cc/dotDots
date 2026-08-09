{
  lib,
  lix,
  user,
  config,
  nixosConfig,
  pkgs,
  src,
  top,
  ...
}: let
  app = "plasma";
  alt = "kde";
  opt = [
    app
    alt
    "plasma6"
  ];

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn (user.interface.desktopEnvironment or null) opt;

  packages = import ./packages.nix {inherit pkgs;};
in {
config = lib.mkMerge [
    (mkIf isAllowed {
    programs = optionalAttrs (config.programs ? ${app}) {
      ${app} = mkMerge [
        {enable = true;}
        (import ./bindings)
        # // import ./files
        (import ./modules {
          inherit
            src
            pkgs
            config
            nixosConfig
            ;
        })
      ];
    };

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/.cache/plasma-config-dump.nix";
      };
      inherit packages;
    };
  })
    {${top}.output = mkIf isAllowed {
    programs = optionalAttrs (config.programs ? ${app}) {
      ${app} = mkMerge [
        {enable = true;}
        (import ./bindings)
        # // import ./files
        (import ./modules {
          inherit
            src
            pkgs
            config
            nixosConfig
            ;
        })
      ];
    };

    home = {
      shellAliases = {
        plasma-config-dump = "nix run github:nix-community/plasma-manager > $DOTS/.cache/plasma-config-dump.nix";
      };
      inherit packages;
    };
  };}
  ];
}
