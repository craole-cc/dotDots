{lix, ...}: let
  inherit (lix.trivial) isNotEmpty;

  default = null;

  resolve = {
    description ? args.description or null,
    name ? args.name or null,
    class ? args.class or null,
    ...
  } @ args:
    if isNotEmpty description
    then description
    else "${toString name} (${toString class})";
in {inherit default resolve;}
