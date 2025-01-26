{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool;
in
{
  options.dots.services.xfce = {
    enable = mkEnableOption "Enable GNOME desktop environment";
  };
}
