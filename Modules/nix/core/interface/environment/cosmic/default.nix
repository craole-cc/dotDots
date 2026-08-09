{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
in {
  config = lib.mkMerge [
    (mkIf (cfg.desktopEnvironment == "cosmic") {
    services.desktopManager.cosmic = {
      enable = true;
      showExcludedPkgsWarning = false;
    };
  })
    {
      ${top}.output = mkIf (cfg.desktopEnvironment == "cosmic") {
    services.desktopManager.cosmic = {
      enable = true;
      showExcludedPkgsWarning = false;
    };
  };
    }
  ];
}
