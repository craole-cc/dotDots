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
  cfg = config.${top}.resolved.${dom}.${mod};
  hw = host.hardware;

  inherit (config.${top}.resolved.interface) displayProtocol;
  inherit (lib.types) listOf package;
  inherit (lib.lists) optionals;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.modules.construction) mkIf;
  pins = pkgs.obs-studio-plugins;
  payload = {programs.${mod} = {inherit (cfg) enable enableVirtualCamera plugins;};};
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.${dom}.${mod} = {
    enable = mkEnable {
      description = "OBS Studio";
      condition = hw.hasVideoCam;
    };
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
        ++ optionals (displayProtocol == "wayland") [wlrobs];
      type = listOf package;
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
