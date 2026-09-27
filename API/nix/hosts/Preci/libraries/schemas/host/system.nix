{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    args ? {},
    system ? args.system or null,
    name ? args.name or null,
    context ? "resolve host system (host \"${toString name}\")",
  }:
    assert requireNonEmpty {
      inherit context;
      path = ["system"];
      set = {inherit system;};
    }; system;
in {inherit default resolve;}
