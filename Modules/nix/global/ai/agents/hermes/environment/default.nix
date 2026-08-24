{
  lix,
  env,
  HOME,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) escapeShellArg;

  env' = rec {
    AUTO_START = 0;
    STARTUP_TIMEOUT = 15;
    HERMES_HOME = HOME + "/.hermes";
    HERMES_GATEWAY_CFG = "${HERMES_HOME}/gateway.json";
    HERMES_ENV_PY = escapeShellArg ./env.py;
    HERMES_ENV_SH = escapeShellArg ./env.sh;
    HINDSIGHT_MODE = "local_external";
    HINDSIGHT_API_URL = "http://100.90.252.109:8888";
    HINDSIGHT_BANK_ID = "hermes";
    HINDSIGHT_RECALL_BUDGET = "mid";
  };
in {
  description = "Hermes Agent";
  env = recursiveUpdate env env';
}
