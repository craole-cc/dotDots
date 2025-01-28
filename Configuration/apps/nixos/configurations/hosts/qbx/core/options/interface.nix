{ config, lib, ... }:
let
  dom = "dots";
  mod = "interface";
  cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum nullOr;
  inherit (config.dots.enums)
    displayProtocols
    loginManagers
    desktopEnvironments
    windowManagers
    users
    ;
in
{
  options.${dom}.${mod} = {
    display = {
      protocol = mkOption {
        description = "Desktop Protocol to use";
        default = "wayland";
        type = enum displayProtocols;
      };
      manager = mkOption {
        description = "Login Manager to use";
        default = "sddm";
        type = nullOr (enum loginManagers);
      };
    };
    desktop = {
      environment = mkOption {
        description = "Desktop Environment to use";
        default = "gnome";
        type = nullOr (enum desktopEnvironments);
      };
      manager = mkOption {
        description = "Window Manager to use";
        default = "hyprland";
        type = nullOr (enum windowManagers);
      };
    };
    autologin = {
      enable = mkEnableOption "Autologin";
      user = mkOption {
        description = "User to use for autologin";
        default = null;
        type = nullOr (enum users);
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.autologin.enable || cfg.autologin.user != null;
        message = "Autologin enabled but no user specified";
      }
    ];
  };
}
