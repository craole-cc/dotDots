{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  cfg = config.${top}.${dom};

  inherit (lib.modules) mkIf;
  inherit (lix.schema.ui) mkUI;

  ui = mkUI {inherit host;};
  inherit (ui.gui) bar window;
  isDank = bar == "dms-shell";
in {
  _module.args.${dom} = cfg // {inherit ui;};

  config = mkIf isDank {
    programs.dms-shell.enable = true;
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = window;
    };
  };
}
