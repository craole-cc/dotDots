{HOME ? "/home/craole", ...}: let
  home = HOME;
in {
  HINDSIGHT_DATA_DIR = "${home}/data/hindsight";
  HINDSIGHT_SECRETS_FILE = "${home}/Private/hindsight.env";
  HINDSIGHT_API_URL = "http://100.90.252.109:8888";
  HINDSIGHT_BIND_ADDRESS = "100.90.252.109";
  HINDSIGHT_LLM_BASE_URL = "http://100.76.128.70:20128/v1";
  HINDSIGHT_LLM_MODEL = "auto/best-fast";
  HINDSIGHT_REFLECT_LLM_MODEL = "auto/best-chat";
  HINDSIGHT_API_WORKER_ID = "hindsight-victus";
}
