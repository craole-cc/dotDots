{
  config,
  lix,
  top,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "programs";
    mod = "bridge";
  };
  inherit (context) cfg mod;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.modules.core.programs) mkPrograms;
  inherit (lix.options.construction) mkEnableOption;

  interface = config.${top}.resolved.interface or {};
in
  mkConfig {
    inherit context;
    options = {
      enable =
        mkEnableOption mod
        // {
          default = interface.enable;
        };
      enableUSWM =
        mkEnableOption mod
        // {
          default = cfg.enable;
        };
    };
    outputs = mkPrograms {
      windowManager = interface.windowManager or null; # TODO: This is ugly
      # enableHyprlandUWSM defaults to true in mkPrograms; override here
      # if a top-level option is ever added to ${top}.programs.hyprland.
    };
  }
