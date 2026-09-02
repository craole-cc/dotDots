{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "obs-studio";
  };
  inherit (context) cfg mod top;

  inherit (lix.lists.construction) optionals;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package;

  hw = host.hardware;
  displayProtocol = config.${top}.resolved.interface.displayProtocol or null;

  defaultPlugins = with pkgs.obs-studio-plugins;
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
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "OBS Studio";
        condition = hw.hasVideoCam;
      };
      enableVirtualCamera = mkEnable {
        description = "OBS virtual camera";
        condition = hw.hasVideoCam;
      };
      plugins = mkOption {
        description = "Optional plugins for OBS.";
        default = defaultPlugins;
        defaultText = literalExpression "default OBS plugin set, plus wlrobs when interface.displayProtocol == \"wayland\"";
        type = listOf package;
      };
    };
    outputs = {
      programs.${mod} = {inherit (cfg) enable enableVirtualCamera plugins;};
    };
  }
