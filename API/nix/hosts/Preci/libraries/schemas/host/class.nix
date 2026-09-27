{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = "nixos";

  resolve = {
    args ? {},
    class ? args.class or default,
    name ? args.name or null,
    context ? "resolve host class (host \"${toString name}\")",
  }:
    assert requireNonEmpty {
      inherit context;
      path = ["class"];
      set = {inherit class;};
    }; class;
in {inherit default resolve;}
