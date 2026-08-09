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
    (mkIf (cfg.windowManager == "niri") {
    programs.niri.enable = true;
    services.iio-niri.enable = true;
  })
    {
      ${top}.output = mkIf (cfg.windowManager == "niri") {
    programs.niri.enable = true;
    services.iio-niri.enable = true;
  };
    }
  ];
}
