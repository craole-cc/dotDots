{
  config,
  host,
  lix,
  top,
  ...
}: let
  dom = "programs";
  mod = "obs-studio";
  cfg = config.${top}.${dom}.${mod};
  hw = host.hardware;
  inherit (lix.types.options) mkEnable mkTrue mkIf;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue "OBS Studio";
    enableVirtualCamera = mkEnable {
      description = "OBS virtual camara";
      condition = hw.hasVideoCam;
    };
  };

  config = mkIf cfg.enable {
    program.${mod} = {
      inherit (cfg) enable enableVirtualCamera;
    };
  };
}
