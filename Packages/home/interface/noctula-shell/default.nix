{
  config,
  nixosConfig,
  host,
  lib,
  lix,
  # pkgs,
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
  enable = (primary || allowed) && config.programs ? ${app};
  monitors = {
    all = getNames {inherit host;};
    primary = getPrimaryName {inherit host;};
    # TODO: We need to store wallpaper path in monitors
  };
  homeDir = config.home.homeDirectory;
  terminal = user.applications.terminal.primary;
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {
        inherit enable;
        settings = mkMerge [
          (import ./bar.nix {inherit monitors;})
          # (import ./color.nix {})
          # (import ./control.nix {inherit terminal;})
          # (import ./desktop.nix {inherit monitors homeDir;})
          # (import ./general.nix {inherit lib config nixosConfig;})
          # (import ./info.nix {inherit host monitors;})
          # (import ./output.nix {inherit homeDir;})
        ];
      }
    ];

    home = {
      sessionVariables.BAR = desired;
      shellAliases = mkIf primary {bar = "${app} &";};
    };
  };
}
