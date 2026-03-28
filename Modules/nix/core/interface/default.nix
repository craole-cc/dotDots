{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";

  inherit (lib.attrsets) attrNames;
  inherit (lib.types) attrs enum nullOr str;
  inherit (lix.filesystem.importers) importAllPaths;
  inherit (lix.types.options) mkTrue mkOption;
  inherit (lix.schema.ui) mkUI;

  ui = mkUI {inherit host;};
  inherit
    (ui.interfaces)
    desktopEnvironments
    displayManagers
    displayProtocols
    windowManagers
    ;
  inherit (ui) sessions;
in {
  imports = importAllPaths ./.;

  options.${top}.${dom} = {
    enable = mkTrue dom;
    available = mkOption {
      description = "Available interfaces";
      default = {
        inherit
          desktopEnvironments
          displayManagers
          windowManagers
          sessions
          ;
      };
    };

    desktopEnvironment = mkOption {
      description = "Desktop environment";
      default = ui.desktopEnvironment;
      type = nullOr (enum (attrNames desktopEnvironments));
    };

    windowManager = mkOption {
      description = "Window manager";
      default = ui.windowManager;
      type = nullOr (enum (attrNames windowManagers));
    };

    displayManager = mkOption {
      description = "Display manager";
      default = ui.displayManager;
      type = nullOr (enum (attrNames displayManagers));
    };

    displayProtocol = mkOption {
      description = "Display protocol";
      default = ui.displayProtocol;
      type = nullOr (enum (attrNames displayProtocols));
    };

    defaultSession = mkOption {
      description = "Default display manager session";
      default = ui.defaultSession;
      type = nullOr str;
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
