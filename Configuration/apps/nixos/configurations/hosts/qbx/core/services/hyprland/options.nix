{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool str;
in
{
  options.dots.services.hyprland = {
    enable = mkEnableOption "Hyprland, the dynamic tiling Wayland compositor that doesn’t sacrifice on its looks.";
  };
}
