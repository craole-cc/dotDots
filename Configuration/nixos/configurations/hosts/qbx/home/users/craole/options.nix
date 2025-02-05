{
  lib,
  ...
}: let
  user = "craole";
  inherit (lib.options) mkOption mkEnableOption;
  inherit
    (lib.types)
    bool
    str
    enum
    nullOr
    ;
in {
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

    desktopEnvironment = mkOption {
      type = nullOr (enum [
        "none"
        "gnome"
        "plasma"
        "xfce"
      ]);
      default = "gnome";
      description = "Selected desktop environment";
    };

    windowManager = mkOption {
      type = nullOr (enum ["hyprland"]);
      default = "hyprland";
      description = "Selected a window manager";
    };
  };
}
