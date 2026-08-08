{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
in {
  config = mkIf (cfg.desktopEnvironment == "cosmic") {
    services.desktopManager.cosmic = {
      enable = true;
      showExcludedPkgsWarning = false;
    };
  };
}
