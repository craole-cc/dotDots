{
  config,
  lib,
  ...
}:
let
  dom = "dots";
  mod = "desktop";
  cfg = config.${dom}.${mod};

  inherit (config.${dom}.enums)
    desktopEnvironments
    windowManagers
    displayProtocols
    loginManagers
    waylandReadyDEs
    ;
  inherit (lib.options)
    mkOption
    mkEnableOption
    ;
  inherit (lib.lists) elem;
  inherit (lib.types)
    enum
    nullOr
    str
    ;
in
{
  options.${dom}.${mod} = {
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
    protocol = mkOption {
      description = "Desktop Protocol to use";
      default = if elem cfg.environment waylandReadyDEs then "wayland" else "xserver";
      type = enum displayProtocols;
    };
    login = {
      manager = mkOption {
        description = "Login Manager to use";
        default = "sddm";
        type = nullOr (enum loginManagers);
      };
      user = mkOption {
        description = "User to use for login";
        default = null;
        type = nullOr str;
      };
      automatically = mkEnableOption "Autologin";
    };
  };
}
