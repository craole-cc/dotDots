{
  host,
  lib,
  ...
}: let
  inherit (lib.lists) map;
  monitors = host.devices.display or [];

  mkMonitor = m: "${m.name}, ${m.resolution}@${toString m.refreshRate}, ${m.position}, ${toString m.scale}";
in {
  monitor = map mkMonitor monitors;
}
