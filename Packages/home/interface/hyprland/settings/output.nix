{
  host,
  lix,
  ...
}: {
  monitor = lix.hardware.display.toHyprlandMonitors {inherit host;};
}
