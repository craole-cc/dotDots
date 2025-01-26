{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool;
in
{
  options.dots.services.gnome = {
    enable = mkEnableOption "GNOME desktop environment";
    wayland.enable = mkOption {
      description = "Use the Wayland protocol instead of X11";
      default = true;
      type = bool;
    };
  };
}
