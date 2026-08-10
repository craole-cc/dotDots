{
  config,
  lib,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.resolved.interface;
  payload = {
    services.desktopManager.cosmic = {
      enable = true;
      showExcludedPkgsWarning = false;
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.desktopEnvironment == "cosmic");
  });
}
