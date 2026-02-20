{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  wayland.windowManager.hyprland.settings =
    mkIf
    (config.wayland.windowManager.hyprland.enable or false) {
      bind = ["ALT, SPACE, exec, vicinae toggle"];
    };
}
