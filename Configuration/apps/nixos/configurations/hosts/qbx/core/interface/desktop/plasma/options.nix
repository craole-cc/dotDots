{ lib, ... }:
let
  inherit (lib.options) mkEnableOption;
in
{
  options.dots.interface.desktopEnvironment.plasma = {
    enable = mkEnableOption "Enable Plasma6 desktop environment";
  };
}
