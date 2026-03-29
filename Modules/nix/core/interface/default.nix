{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";

  inherit (lib.types) nullOr str;
  inherit (lix.filesystem.importers) importAllPaths;
  inherit (lix.types.options) mkTrue mkOption mkEnumOption;
  inherit (lix.schema.ui) mkUI;

  ui = mkUI {inherit host;};
  inherit
    (ui)
    sessions
    shells
    desktopEnvironments
    displayManagers
    displayProtocols
    windowManagers
    ;
in {
  imports = importAllPaths ./.;

  options.${top}.${dom} = {
    enable = mkTrue dom;
    available = mkOption {
      description = "Available interfaces";
      default = {
        inherit
          desktopEnvironments
          windowManagers
          ;
        inherit sessions;
      };
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
      default = ui.shell.login;
      input = shells;
      nullable = true;
    };

    # windowShell = mkOption {
    #   description = "Status bar / window shell component";
    #   default = ui.windowShell;
    #   type = nullOr str;
    # };
    # shell = mkOption {
    #   description = "Shell";
    #   default = ui.shell;
    #   type = nullOr (enum shells.values);
    # };
    # shellPrompt = mkOption {
    #   description = "Shell prompt";
    #   default = ui.shellPrompt;
    #   type = nullOr str;
    # };
    # desktopShell = mkOption {
    #   description = "Desktop manager UI shell";
    #   default = ui.desktopShell;
    #   type = nullOr str;
    # };
    # terminal = mkOption {
    #   description = "Default terminal";
    #   default = ui.terminal;
    #   type = nullOr str;
    # };
    # appLauncher = mkOption {
    #   description = "Application launcher";
    #   default = ui.appLauncher;
    #   type = nullOr str;
    # };
    # fileManager = mkOption {
    #   description = "File manager";
    #   default = ui.fileManager;
    #   type = nullOr str;
    # };
    # notificationDaemon = mkOption {
    #   description = "Notification daemon";
    #   default = ui.notificationDaemon;
    #   type = nullOr str;
    # };
    # bar = mkOption {
    #   description = "Status bar";
    #   default = ui.bar;
    #   type = nullOr str;
    # };
    # keyboard = mkOption {
    #   description = "Keyboard config and bindings";
    #   default = ui.keyboard;
    #   type = attrs;
    # };
  };
}
