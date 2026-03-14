{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.wm == "niri") {
    programs.niri.enable = true;
    services.iio-niri.enable = true;
  };
}
