{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    stateVersion ? args.stateVersion or null,
    name ? args.name or null,
    context ? "resolve host stateVersion (host \"${toString name}\")",
    ...
  } @ args:
    assert requireNonEmpty {
      inherit context;
      path = ["stateVersion"];
      set = {inherit stateVersion;};
    }; stateVersion;
in {inherit default resolve;}
