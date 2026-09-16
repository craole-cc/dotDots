{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;

  env' = {
    AUTO_START = env.AUTO_START or 0;
    STARTUP_TIMEOUT = env.STARTUP_TIMEOUT or 15;
    HERMES_ENV_PY = "${./env.py}";
    HERMES_ENV_SH = "${./env.sh}";
  };
in {
  description = "Hermes Agent";
  env = recursiveUpdate env env';
}
