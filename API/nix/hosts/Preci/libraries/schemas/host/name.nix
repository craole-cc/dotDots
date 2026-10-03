{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    name ? args.name or null,
    context ? "resolve host name",
    ...
  } @ args:
    assert requireNonEmpty {
      inherit context;
      path = ["name"];
      set = {inherit name;};
    }; name;
in {inherit default resolve;}
