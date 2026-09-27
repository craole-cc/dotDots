{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    args ? {},
    stateVersion ? args.stateVersion or null,
    name ? args.name or null,
    context ? "resolve host stateVersion (host \"${toString name}\")",
  }:
    assert requireNonEmpty {
      inherit context;
      path = ["stateVersion"];
      set = {inherit stateVersion;};
    }; stateVersion;
in {inherit default resolve;}
