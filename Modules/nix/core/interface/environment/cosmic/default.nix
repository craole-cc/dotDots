{
  config,
  lib,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.inputs.interface;
  payload = {
    services.desktopManager.cosmic = {
      enable = true;
      showExcludedPkgsWarning = false;
    };
  };
  inherit (lix.modules.core._) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.desktopEnvironment == "cosmic");
  });
}
