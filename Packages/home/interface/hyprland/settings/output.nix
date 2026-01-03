{
  host,
  lix,
  ...
}: let
  displays = host.devices.display or {};
  inherit (lix.hardware.display) toHyprlandMonitors;
in {
  wayland.windowManager.hyprland.settings = {
    monitor = toHyprlandMonitors displays;
  };
}
