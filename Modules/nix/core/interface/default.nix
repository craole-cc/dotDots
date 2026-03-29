{
  # config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  # cfg = config.${top}.${dom};

  inherit (lib.modules) mkIf;
  inherit (lib.types) nullOr str;
  inherit (lix.filesystem.importers) importAllPaths;
  inherit (lix.types.options) mkTrue mkOption mkEnumOption;
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
  isDank = ui.gui.bar == "dms-shell";
in {
  imports = importAllPaths ./.;

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
      description = "Login shell";
      default = ui.shell.system;
      input = shells.system;
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

  config = mkIf isDank {
    programs.dms-shell.enable = true;
    services.displayManager.dms-greeter.enable = true;
  };
}
