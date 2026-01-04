{
  config,
  host,
  lib,
  lix,
  pkgs,
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
    allNames = getNames {inherit host;};
    primaryName = getPrimaryName {inherit host;};
    # TODO: We need to store wallpaper path in monitors
  };
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {inherit enable;}
      {
        settings = mkMerge [
          (import ./audio.nix)
          (import ./bar.nix {inherit monitors;})
          (import ./color.nix)
          (import ./control.nix)
          (import ./desktop.nix {inherit monitors;})
          (import ./general.nix {inherit pkgs;})
          (import ./info.nix {inherit host monitors;})
          (import ./output.nix)
        ];
      }
    ];

    home = {
      sessionVariables.BAR = desired;
      shellAliases = mkIf primary {bar = "${app} &";};
    };
  };
}
