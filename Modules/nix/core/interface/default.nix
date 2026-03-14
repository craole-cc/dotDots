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
  iface = host.interface;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum nullOr str;
  inherit
    (lix.enums)
    desktopEnvironments
    windowManagers
    displayManagers
    displayProtocols
    shells
    ;
in {
  imports = lix.filesystem.importers.importAllPaths ./.;

  options.${top}.${dom} = {
    enable = mkEnableOption dom // {default = true;};
    wm = mkOption {
      description = "Window manager";
      default = iface.windowManager or null;
      type = nullOr (enum windowManagers.values);
    };
    de = mkOption {
      description = "Desktop environment";
      default = iface.desktopEnvironment or null;
      type = nullOr (enum desktopEnvironments.values);
    };
    dm = mkOption {
      description = "Display manager";
      default = iface.displayManager or null;
      type = nullOr (enum displayManagers.values);
    };
    dp = mkOption {
      description = "Display protocol";
      default = iface.displayProtocol or "wayland";
      type = enum displayProtocols.values;
    };
    bar = mkOption {
      description = "Status bar";
      default = iface.bar or null;
      type = nullOr str;
    };
    shell = mkOption {
      description = "Shell";
      default = iface.shell or null;
      type = nullOr (enum shells.values);
    };
    prompt = mkOption {
      description = "Shell prompt";
      default = iface.prompt or null;
      type = nullOr str;
    };
    uiShell = mkOption {
      description = "UI shell";
      default = iface.uiShell or null;
      type = nullOr str;
    };
    terminal = mkOption {
      description = "Default terminal";
      default = iface.terminal or null;
      type = nullOr str;
    };
    launcher = mkOption {
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

  config = mkIf cfg.enable {};
}
