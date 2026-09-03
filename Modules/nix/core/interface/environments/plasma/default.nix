{
  config,
  lix,
  pkgs,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "environment";
    mod = "plasma";
  };
  inherit (context) cfg ctx;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;} // ctx.wantsPlasma;
    };
    outputs = {
      services.desktopManager.plasma6.enable = cfg.enable;
      environment.systemPackages = with pkgs.kdePackages; [
        plasma-browser-integration
        kde-gtk-config
        kdialog
      ];
    };
  }
