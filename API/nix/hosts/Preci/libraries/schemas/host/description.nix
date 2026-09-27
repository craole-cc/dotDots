{lix, ...}: let
  inherit (lix.trivial) isNotEmpty;

  default = null;

  resolve = {
    args ? {},
    description ? args.description or null,
    name ? args.name or null,
    class ? args.class or null,
  }:
    if isNotEmpty description
    then description
    else "${toString name} (${toString class})";
in {inherit default resolve;}
