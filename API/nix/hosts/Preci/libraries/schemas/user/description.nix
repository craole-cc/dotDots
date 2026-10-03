{lix, ...}: let
  inherit (lix.trivial) isNotEmpty;

  default = null;

  resolve = {
    description ? args.description or null,
    name ? args.name or null,
    role ? args.role or null,
    ...
  } @ args:
    if isNotEmpty description
    then description
    else "${toString name} (${toString role})";
in {inherit default resolve;}
