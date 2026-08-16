{
  lix,
  config,
  lib,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lib.modules) mkIf;
  inherit (config.dots.interface) display desktop;
  cfgEnabled = desktop.environment == "gnome" && display.protocol == "xserver";
  nvidiaEnabled = config.hardware.nvidia.modesetting.enable;
  payload = {
    services.xserver = {
      enable = true;
      videoDrivers =
        if nvidiaEnabled
        then ["nvidia"]
        else [];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfgEnabled;
  });
}
