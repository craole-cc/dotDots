# Packages/home/bar/noctalia/default.nix
{
  config,
  lib,
  lix,
  user,
  host,
  ...
}: let
  app = "noctalia-shell";
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.hardware.display) getDisplaysSorted getDisplaysPrimary;

  desired = user.interface.bar or null;
  primary = desired != null;
  allowed = isIn app (user.applications.allowed or []);
  enable = (primary || allowed) && config.programs ? ${app};
  monitors = {
    all = getDisplaysSorted {inherit host;};
    primary = getDisplaysPrimary {inherit host;};
  };
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {inherit enable;}
      (import ./audio.nix)
      (import ./bar.nix {inherit monitors;})
      (import ./launcher.nix)
    ];

    home = {
      sessionVariables.BAR = desired;
      shellAliases = mkIf primary {bar = "${app} &";};
    };
  };
}
