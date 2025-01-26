# user-options.nix
{ lib, ... }:
let
  user = "craole";
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool str;
in
{
  options.dots.users.${user} = {
    enable = mkEnableOption "Craole";
    name = mkOption {
      description = "Username";
      default = user;
      type = str;
    };
    fullName = mkOption {
      description = "User's full name";
      default = "Craig Cole";
      type = str;
    };
    autoLogin = mkOption {
      description = "Enable auto-login for the user";
      default = true;
      type = bool;
    };
    backupFileExtension = mkOption {
      description = "Backup file extension";
      default = "BaC";
      type = str;
    };

    gnome.enable = mkOption {
      description = "Gnome";
      default = true;
      type = bool;
    };

    hyprland.enable = mkOption {
      description = "Hyprland";
      default = true;
      type = bool;
    };

    plasma.enable = mkOption {
      description = "Plasma";
      default = true;
      type = bool;
    };

    xfce.enable = mkOption {
      description = "Xfce";
      default = true;
      type = bool;
    };
  };
}
