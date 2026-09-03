{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "manager";
    mod = "hyprland";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;} // ctx.wantsHyprland;
    };
    outputs = {
      programs.hyprland = {
        inherit (cfg) enable;
        withUWSM = true;
      };
    };
  }
