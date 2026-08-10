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
    programs.niri.enable = true;
    services.iio-niri.enable = true;
  };
  inherit (lix.modules.core._) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.windowManager == "niri");
  });
}
