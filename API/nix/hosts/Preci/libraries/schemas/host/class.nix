{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = "nixos";

  resolve = {
    class ? args.class or default,
    name ? args.name or null,
    context ? "resolve host class (host \"${toString name}\")",
    ...
  } @ args:
    assert requireNonEmpty {
      inherit context;
      path = ["class"];
      set = {inherit class;};
    }; class;
in {inherit default resolve;}
