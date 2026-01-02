{
  host,
  lib,
  ...
}: let
  inherit (lib.lists) map;
  monitors = host.devices.display or [];

  mkMonitor = monitor: let
    base = with monitor; "${name}, ${resolution}@${toString refreshRate}, ${position}, ${toString scale}";
    rotation =
      if monitor ? transform
      then ", transform, ${toString monitor.transform}"
      else "";
  in
    base + rotation;
in {monitor = map mkMonitor monitors;}
