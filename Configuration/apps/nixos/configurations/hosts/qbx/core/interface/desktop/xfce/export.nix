{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dots.services.xfce;
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = { };
    };
  };
}
