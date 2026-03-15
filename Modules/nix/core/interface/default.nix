{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  iface = host.interface;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum nullOr str;
  inherit (lix.filesystem.importers) importAllPaths;
  inherit
    (lix.enums)
    desktopEnvironments
    windowManagers
    displayManagers
    displayProtocols
    shells
    ;
in {
  imports = importAllPaths ./.;

  options.${top}.${dom} = {
    enable = mkEnableOption dom // {default = true;};
    windowManager = mkOption {
      description = "Window manager";
      default = iface.windowManager or null;
      type = nullOr (enum windowManagers.values);
    };
    desktopEnvironment = mkOption {
      description = "Desktop environment";
      default = iface.desktopEnvironment or null;
      type = nullOr (enum desktopEnvironments.values);
    };
    displayManager = mkOption {
      description = "Display manager";
      default = iface.displayManager or null;
      type = nullOr (enum displayManagers.values);
    };
    displayProtocol = mkOption {
      description = "Display protocol";
      default = iface.displayProtocol or "wayland";
      type = enum displayProtocols.values;
    };
    defaultSession = mkOption {
      description = "Default display manager session";
      default = iface.defaultSession or null;
      type = nullOr str;
    };
    windowShell = mkOption {
      description = "Status bar / window shell component";
      default = iface.bar or null;
      type = nullOr str;
    };
    shell = mkOption {
      description = "Shell";
      default = iface.shell or null;
      type = nullOr (enum shells.values);
    };
    shellPrompt = mkOption {
      description = "Shell prompt";
      default = iface.prompt or null;
      type = nullOr str;
    };
    desktopShell = mkOption {
      description = "Desktop manager UI shell";
      default = iface.uiShell or null;
      type = nullOr str;
    };
    terminal = mkOption {
      description = "Default terminal";
      default = iface.terminal or null;
      type = nullOr str;
    };
    appLauncher = mkOption {
      description = "Application launcher";
      default = iface.launcher or null;
      type = nullOr str;
    };
    fileManager = mkOption {
      description = "File manager";
      default = iface.fileManager or null;
      type = nullOr str;
    };
    notificationDaemon = mkOption {
      description = "Notification daemon";
      default = iface.notificationDaemon or null;
      type = nullOr str;
    };
  };
}
