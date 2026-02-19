{
  config,
  nixosConfig,
  host,
  lib,
  lix,
  user,
  ...
}: let
  app = "noctalia-shell";
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.hardware.display) getNames getPrimaryName;

  desired = user.interface.bar or null;
  primary = desired != null;
  allowed = isIn app (user.applications.allowed or []);

  # Check if the program option exists in home-manager
  programExists = config ? programs.${app};

  # Only enable if both conditions are met
  enable = (primary || allowed) && programExists;

  monitors = {
    all = getNames {inherit host;};
    primary = getPrimaryName {inherit host;};
  };
  homeDir = config.home.homeDirectory;
  terminal = user.applications.terminal.primary;
  wallpapers = homeDir + "/Pictures/Wallpapers";
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {
        enable = true;
        settings = mkMerge [
          (import ./bar.nix {inherit monitors;})
          (import ./color.nix {})
          (import ./control.nix {inherit terminal;})
          (import ./desktop.nix {inherit monitors wallpapers;})
          (import ./general.nix {inherit lib config nixosConfig;})
          (import ./info.nix {inherit host monitors;})
          (import ./output.nix {inherit homeDir;})
        ];
      }
    ];

    home = {
      sessionVariables.BAR = desired;
      shellAliases = mkIf primary {bar = "${app} &";};
    };
  };
}
