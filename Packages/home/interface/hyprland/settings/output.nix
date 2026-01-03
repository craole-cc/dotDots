{
  host,
  lix,
  ...
}: {
  wayland.windowManager.hyprland.settings.monitor =
    lix.hardware.display.toHyprlandMonitors {inherit host;};
}
