{ lib, ... }:
let
  inherit (lib.options) mkEnableOption;
in
{
  options.dots.interface.windowManager.hyprland = {
    enable = mkEnableOption "Hyprland, the dynamic tiling Wayland compositor that doesn’t sacrifice on its looks.";
  };
}
