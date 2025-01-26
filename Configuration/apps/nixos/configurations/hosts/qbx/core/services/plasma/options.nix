{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool;
in
{
  options.dots.services.plasma = {
    enable = mkEnableOption "Enable Plasma6 desktop environment";
  };
}
