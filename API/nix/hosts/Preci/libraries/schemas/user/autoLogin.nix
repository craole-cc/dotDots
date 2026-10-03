{lix, ...}: let
  inherit (lix.debug) requireThat;
  inherit (lix.trivial) isBool;

  default = false;

  resolve = {
    args ? {},
    autoLogin ? args.autoLogin or default,
    name ? args.name or null,
    context ? "resolve user autoLogin (user \"${toString name}\")",
  }:
    assert requireThat {
      inherit context;
      condition = isBool autoLogin;
      message = "autoLogin must be a boolean, got '${toString autoLogin}'";
    }; autoLogin;
in {inherit default resolve;}
