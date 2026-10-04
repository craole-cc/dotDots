{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    system ? args.system or null,
    name ? args.name or null,
    context ? "resolve host system (host \"${toString name}\")",
    ...
  } @ args:
    assert requireNonEmpty {
      inherit context;
      path = ["system"];
      set = {inherit system;};
    }; system;
in {inherit default resolve;}
