{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;

  env' = {
    AUTO_START = 0;
    STARTUP_TIMEOUT = 15;
    HERMES_ENV_PY = "${./env.py}";
    HERMES_ENV_SH = "${./env.sh}";
    HINDSIGHT_MODE = "local_external";
    HINDSIGHT_API_URL = env.HINDSIGHT_API_URL or "http://100.90.252.109:8888";
    HINDSIGHT_BANK_ID = env.HINDSIGHT_BANK_ID or "hermes";
    HINDSIGHT_RECALL_BUDGET = env.HINDSIGHT_RECALL_BUDGET or "mid";
  };
in {
  description = "Hermes Agent";
  env = recursiveUpdate env env';
}
