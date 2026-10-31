{
  apps,
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "clock";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = apps.needs "clock-rs";
    };
    outputs.programs.clock-rs = {
      enable = true;
      settings = {
        general = {
          color = "magenta";
          interval = 250;
          blink = true;
          bold = true;
        };

        position = {
          horizontal = "start";
          vertical = "end";
        };

        date = {
          fmt = "%A, %B %d, %Y";
          use_12h = true;
          utc = false;
          hide_seconds = false;
        };
      };
    };
  }
