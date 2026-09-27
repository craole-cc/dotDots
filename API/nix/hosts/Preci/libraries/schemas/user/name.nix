{lix, ...}: let
  inherit (lix.debug) requireNonEmpty;

  default = null;

  resolve = {
    args ? {},
    name ? args.name or null,
    context ? "resolve user name",
  }:
    assert requireNonEmpty {
      inherit context;
      path = ["name"];
      set = {inherit name;};
    }; name;
in {inherit default resolve;}
