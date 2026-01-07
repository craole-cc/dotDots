{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf mkForce;
in {
  wayland.windowManager.hyprland.settings =
    mkIf
    (config.wayland.windowManager.hyprland.enable or false) {
      bind = mkForce ["ALT, SPACE, exec, vicinae toggle"];
    };
}
