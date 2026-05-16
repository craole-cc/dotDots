{
  host,
  user,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";

  inherit (lix.schema.ui) mkUI;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) attrsOf nullOr str submodule;
  
  ui = mkUI {inherit host user;};
in {
  options.${top}.${dom} = {
    enable = mkEnableOption dom // {default = ui.enable;};

    desktopEnvironment = mkOption {
      description = "Desktop Environment";
      default = ui.desktopEnvironment;
      type = nullOr str;
    };

    windowManager = mkOption {
      description = "Window Manager / Compositor";
      default = ui.windowManager;
      type = nullOr str;
    };

    displayManager = mkOption {
      description = "Display Manager";
      default = ui.displayManager;
      type = nullOr str;
    };

    displayProtocol = mkOption {
      description = "Display Protocol";
      default = ui.displayProtocol;
      type = nullOr str;
    };

    session = mkOption {
      description = "Default display manager session";
      default = ui.session;
      type = nullOr str;
    };

    shell = mkOption {
      description = "Interactive shell";
      default = ui.shell.interactive;
      type = nullOr str;
    };

    keyboard = mkOption {
      description = "Keyboard config and bindings";
      default = ui.keyboard;
      type = ui.options.keyboard.type;
    };

    apps = mkOption {
      description = "Default applications";
      default = ui.apps;
      type = attrsOf (submodule {
        options = {
          pri = mkOption {
            type = nullOr str;
            default = null;
          };
          sec = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
    };

    panel = mkOption {
      description = "Desktop panel/bar";
      default = ui.panel;
      type = nullOr str;
    };

    notifier = mkOption {
      description = "Desktop notification daemon";
      default = ui.notifier;
      type = nullOr str;
    };
  };
}
