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
  inherit (context) cfg mod;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package;

  hw = host.hardware;
  defaultPlugins = [];
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
