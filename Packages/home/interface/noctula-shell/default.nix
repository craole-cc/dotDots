{
  config,
  lib,
  lix,
  user,
  #   pkgs,
  ...
}: let
  app = "noctalia-shell";
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.lists.predicates) isIn;
  desired = user.interface.bar or null;
  primary = desired != null;
  allowed = isIn app (user.applications.allowed or []);
  enable = (primary || allowed) && config.programs?${app};
in {
  config = mkIf enable {
    programs.${app} = mkMerge [
      {inherit enable;}
      (import ./audio.nix)
      (import ./bar.nix)
      (import ./launcher.nix)
    ];
    home = {
      sessionVariables.BAR = desired;
      shellAliases = mkIf primary {bar = "${app} &";};
    };
  };
}
