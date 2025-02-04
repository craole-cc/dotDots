{ config, lib, ... }:
with lib;
with types;
let
  app = "btop";
  cfg = config.dot.applications.${app};
in
{
  options.dot.applications.${app} = {
    enable = mkEnableOption "${app}";
  };

  # config = mkIf cfg.enable {

  # }
}
