{lix, ...}: let
  inherit (lix.debug) requireThat;

  default = true;

  resolve = {
    args ? {},
    enable ? args.enable or default,
    name ? args.name or null,
    context ? "resolve user enable (user \"${toString name}\")",
  }:
    assert requireThat {
      inherit context;
      condition = builtins.isBool enable;
      message = "enable must be a boolean, got '${toString enable}'";
    }; enable;
in {inherit default resolve;}
