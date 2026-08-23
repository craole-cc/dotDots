{
  lix,
  env,
  HOME,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) escapeShellArg;
in {
  description = "Hermes Agent";

  env = recursiveUpdate env {
    AUTO_START = 0;
    STARTUP_TIMEOUT = 15;
    HERMES_HOME = HOME + "/.hermes";
    HERMES_ENV_PY = escapeShellArg ./env.py;
    HERMES_ENV_SH = escapeShellArg ./env.sh;
  };
}
