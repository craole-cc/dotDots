{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) string;
in
{
  options.dots.services.hyprland = {
    enable = mkEnableOption "Enable GNOME desktop environment";
    user = mkOption {
      description = "Hyprland user";
      default = "craole";
      type = string;
    };
  };
}
