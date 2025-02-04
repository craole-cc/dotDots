{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool string;
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
