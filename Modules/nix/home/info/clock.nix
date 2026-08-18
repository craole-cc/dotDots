{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {
    programs.clock-rs = {
      enable = config.${top}.resolved.applications.utilities.clock.enable;
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
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
