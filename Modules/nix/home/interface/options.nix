{
  host,
  lib,
  lix,
  user,
  top,
  # config,
  ...
}: let
  dom = "interface";
  # cfg = config.${top}.${dom};
  inherit (lib.attrsets) attrNames;
  inherit (lib.types) enum nullOr;
  inherit (lix.types.options) mkTrue mkOption;
  inherit (lix.schema.ui) mkUI;
  iface = mkUI {inherit host user;};
  inherit (iface.interfaces) desktopEnvironments displayManagers windowManagers;
  inherit (iface) sessions;
in {
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
      default = iface.desktopEnvironment;
      type = nullOr (enum (attrNames desktopEnvironments));
    };
    windowManager = mkOption {
      description = "Window manager";
      default = iface.windowManager;
      type = nullOr (enum (attrNames windowManagers));
    };
    displayManager = mkOption {
      description = "Display manager";
      default = iface.displayManager;
      type = nullOr (enum (attrNames displayManagers));
    };
    # displayProtocol = mkOption {
    #   description = "Display protocol";
    #   default = iface.displayProtocol;
    #   type = enum displayProtocols.values;
    # };
    # defaultSession = mkOption {
    #   description = "Default display manager session";
    #   default = iface.defaultSession;
    #   type = nullOr str;
    # };
    # windowShell = mkOption {
    #   description = "Status bar / window shell component";
    #   default = iface.windowShell;
    #   type = nullOr str;
    # };
    # shell = mkOption {
    #   description = "Shell";
    #   default = iface.shell;
    #   type = nullOr (enum shells.values);
    # };
    # shellPrompt = mkOption {
    #   description = "Shell prompt";
    #   default = iface.shellPrompt;
    #   type = nullOr str;
    # };
    # desktopShell = mkOption {
    #   description = "Desktop manager UI shell";
    #   default = iface.desktopShell;
    #   type = nullOr str;
    # };
    # # terminal = mkOption {
    # #   description = "Default terminal";
    # #   default = iface.terminal;
    # #   type = nullOr str;
    # # };
    # appLauncher = mkOption {
    #   description = "Application launcher";
    #   default = iface.appLauncher;
    #   type = nullOr str;
    # };
    # # fileManager = mkOption {
    # #   description = "File manager";
    # #   default = iface.fileManager;
    # #   type = nullOr str;
    # # };
    # notificationDaemon = mkOption {
    #   description = "Notification daemon";
    #   default = iface.notificationDaemon;
    #   type = nullOr str;
    # };
    # bar = mkOption {
    #   description = "Status bar";
    #   default = iface.bar;
    #   type = nullOr str;
    # };
    # keyboard = mkOption {
    #   description = "Keyboard config and bindings";
    #   default = iface.keyboard;
    #   type = attrs;
    # };
  };
}
