{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool;
in
{
  options.dots.env.gnome = {
    enable = mkEnableOption "Enable GNOME desktop environment";
    wayland.enable = mkOption {
      description = "Use the Wayland protocol instead of X11";
      default = true;
      type = bool;
    };
  };
}
