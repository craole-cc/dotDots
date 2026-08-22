{
  lix,
  HOME ? "/home/craole",
  ...
}: let
  inherit (lix.strings.transformation) escapeShellArg;

  AUTO_START = 0;
  STARTUP_TIMEOUT = 15;
  HERMES_HOME = HOME + "/.hermes";
  HERMES_ENV_PY = escapeShellArg ./env.py;
  HERMES_ENV_SH = escapeShellArg ./env.sh;
in {
  description = "Hermes Agent";
  env = {
    inherit
      AUTO_START
      HERMES_ENV_PY
      HERMES_ENV_SH
      HERMES_HOME
      STARTUP_TIMEOUT
      ;
  };
}
