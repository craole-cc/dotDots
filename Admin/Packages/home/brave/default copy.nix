{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.programs.brave;
in {
  options.programs.brave = {
    enable = mkEnableOption "Brave Browser";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.brave];
  };
}
