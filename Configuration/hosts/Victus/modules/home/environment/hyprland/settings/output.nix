{
  host,
  lib,
  ...
}:
let
  inherit (host.devices) display;
  inherit (lib.lists) map;

  mkMonitor =
    m: "${m.name}, ${m.resolution}@${toString m.refreshRate}, ${m.position}, ${toString m.scale}";
in
{
  monitor = map mkMonitor display;
}
