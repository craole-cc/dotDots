{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";

  inherit (lib.types) nullOr str;
  inherit (lix.options.construction) mkEnumOption mkOption mkTrue;
  inherit (lix.schema.ui) mkUI;

  ui = mkUI {inherit host;};
  inherit
    (ui.composites)
    types
    shells
    desktopEnvironments
    displayManagers
    displayProtocols
    windowManagers
    ;
in {
  options.${top}.${dom} = {
    enable = mkTrue dom;

    available = mkOption {
      description = "Available interfaces";
      default = {inherit desktopEnvironments windowManagers;};
    };

    desktopEnvironment = mkEnumOption {
      description = "Desktop Environment";
      default = ui.desktopEnvironment;
      input = desktopEnvironments;
    };

    windowManager = mkEnumOption {
      description = "Window Manager";
      default = ui.windowManager;
      input = windowManagers;
    };

    displayManager = mkEnumOption {
      description = "Display Manager";
      default = ui.displayManager;
      input = displayManagers;
    };

    displayProtocol = mkEnumOption {
      description = "Display Protocols";
      default = ui.displayProtocol;
      input = displayProtocols;
    };

    defaultSession = mkOption {
      description = "Default display manager session";
      default = ui.defaultSession;
      type = nullOr str;
    };

    defaultApps = mkOption {
      description = "Default applications";
      default = ui.apps;
      type = types.apps;
    };

    shell = mkEnumOption {
      description = "Login shell";
      default = ui.shell.system;
      input = shells.system;
    };

    compositor = mkEnumOption {
      description = "Windowing compositor";
      default = ui.gui.window;
      input = [];
    };

    panel = mkOption {
      default = ui.gui.bar;
      input = [];
    };

    notificationDaemon = mkOption {
      default = ui.gui.notification;
      input = [];
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
