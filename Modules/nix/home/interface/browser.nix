{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "common";
    mod = "browser";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  desktop = "zen-twilight.desktop";
  associations = {
    "application/xhtml+xml" = desktop;
    "text/html" = desktop;
    "x-scheme-handler/http" = desktop;
    "x-scheme-handler/https" = desktop;
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = true;
      };
    };
    outputs = {
      xdg.mimeApps = {
        enable = cfg.enable;
        associations.added = associations;
        defaultApplications = associations;
      };
      home.sessionVariables.BROWSER = "zen";
    };
  }
