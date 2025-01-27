{ lib, ... }:
let
  inherit (lib.options) mkEnableOption;
in
{
  options.dots.interface.desktopEnvironment.xfce = {
    enable = mkEnableOption "Enable GNOME desktop environment";
  };
}
