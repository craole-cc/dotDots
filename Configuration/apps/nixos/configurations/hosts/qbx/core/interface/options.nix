{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) oneOf;
in
{
  options.interface = {
    display = {
      protocol = mkOption {
        description = "Desktop Protocol to use";
        default = "wayland";
        types = oneOf [
          "wayland"
          "xserver"
        ];
      };
      manager = mkOption {
        description = "Login Manager to use";
        default = "sddm";
        types = oneOf [
          "sddm"
          "gdm"
          "lightdm"
          "none"
        ];
      };
    };
    desktop = {
      environment = mkOption {
        description = "Desktop Environment to use";
        default = "gnome";
        types = oneOf [
          "gnome"
          "plasma"
          "xfce"
          "none"
        ];
      };
      manager = mkOption {
        description = "Window Manager to use";
        default = "hyprland";
        types = oneOf [
          "hyprland"
          "none"
          "qtile"
        ];
      };
    };
    autologin = {
      enable = mkEnableOption "Autologin";
      user = mkOption {
        description = "User to use for autologin";
        default = null;
      };
    };
  };
}
