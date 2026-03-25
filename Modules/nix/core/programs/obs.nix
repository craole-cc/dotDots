{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "programs";
  mod = "obs-studio";
  cfg = config.${top}.${dom}.${mod};
  hw = host.hardware;

  inherit (config.${top}.interface) displayProtocol;
  inherit (lib.types) listOf package;
  inherit (lib.lists) optionals;
  inherit (lix.types.options) mkEnable mkOption mkTrue mkIf;
  pins = pkgs.obs-studio-plugins;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue "OBS Studio";
    enableVirtualCamera = mkEnable {
      description = "OBS virtual camara";
      condition = hw.hasVideoCam;
    };
    plugins = mkOption {
      description = "Optional plugins for OBS.";
      default = with pins;
        [
          droidcam-obs
          input-overlay
          obs-advanced-masks
          obs-aitum-multistream
          obs-mute-filter
          obs-retro-effects
          obs-source-record
          obs-source-switcher
          obs-vertical-canvas
        ]
        ++ optionals (displayProtocol == "wayland") [
          wlrobs
        ];
      type = listOf package;
    };
  };

  config = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable enableVirtualCamera plugins;
    };
  };
}
