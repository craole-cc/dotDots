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
  inherit (lix.hardware.display) getPrimaryMonitor;

  desired = user.interface.bar or null;
  primary = desired != null;
  allowed = isIn app (user.applications.allowed or []);
  enable = (primary || allowed) && config.programs ? ${app};

  monitors = rec {
    all = host.devices.display or {};
    primary = getPrimaryMonitor all;
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
