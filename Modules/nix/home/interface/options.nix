{
  host,
  user,
  lib,
  lix,
  top,
  ...
}:
let
  dom = "interface";

  inherit (lib.types) nullOr str;
  inherit (lix.types.options) mkTrue mkOption mkEnumOption;
  inherit (lix.schema.ui) mkUI;

  ui = mkUI { inherit host user; };
  inherit (ui.composites)
    types
    shells
    desktopEnvironments
    displayManagers
    displayProtocols
    windowManagers
    ;
in
{
  options.${top}.${dom} = {
    enable = mkTrue dom;

    available = mkOption {
      description = "Available interfaces";
      default = { inherit desktopEnvironments windowManagers; };
    };

    desktopEnvironment = mkEnumOption {
      description = "Desktop Environment";
      default = ui.desktopEnvironment;
      input = desktopEnvironments;
      nullable = true;
    };

    windowManager = mkEnumOption {
      description = "Window Manager";
      default = ui.windowManager;
      input = windowManagers;
      nullable = true;
    };

    displayManager = mkEnumOption {
      description = "Display Manager";
      default = ui.displayManager;
      input = displayManagers;
      nullable = true;
    };

    displayProtocol = mkEnumOption {
      description = "Display Protocols";
      default = ui.displayProtocol;
      input = displayProtocols;
      nullable = true;
    };

    defaultSession = mkOption {
      description = "Default display manager session";
      default = ui.defaultSession;
      type = nullOr str;
    };

    shell = mkEnumOption {
      description = "Interactive shell";
      default = ui.shell.interactive;
      input = shells.interactive;
      nullable = true;
    };

    apps = mkOption {
      description = "Default applications";
      default = ui.apps;
      type = types.apps;
    };

    gui = mkOption {
      description = "GUI components";
      default = ui.gui;
      type = types.gui;
    };

    keyboard = mkOption {
      description = "Keyboard config and bindings";
      default = ui.keyboard;
      type = types.keyboard;
    };
  };
}
