{
  config,
  lib,
  ...
}:
let
  dom = "DOTS";
  mod = "enums";

  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;
  inherit (lib.attrsets) attrNames;
in
{
  options.${dom}.${mod} = {
    displayProtocols = mkOption {
      description = "Desktop Protocols";
      default = [
        "wayland"
        "xserver"
      ];
      type = listOf str;
    };

    loginManagers = mkOption {
      description = "Login Managers";
      default = [
        "sddm"
        "gdm"
        "lightdm"
        "kmscon"
      ];
      type = listOf str;
    };

    windowManagers = mkOption {
      description = "Window Managers";
      default = [
        "hyprland"
        "qtile"
      ];
      type = listOf str;
    };

    desktopEnvironments = mkOption {
      description = "Desktop Environments";
      default = [
        "gnome"
        "plasma"
        "xfce"
        "budgie"
      ];
      type = listOf str;
    };

    waylandReadyDEs = mkOption {
      description = "Wayland Ready Desktop Environments";
      default = [
        "gnome"
        "plasma"
      ];
      type = listOf str;
    };

    users = mkOption {
      description = "Users";
      default = attrNames config.${dom}.users;
      type = listOf str;
    };
  };
}
