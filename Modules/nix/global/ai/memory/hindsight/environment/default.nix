# environment/default.nix
{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) toUpper;

  HOME = env.HOME or "/home/craole";
  PRIVATE = env.PRIVATE or "${HOME}/Private";

  target = env.name or "hindsight";
  prefix = toUpper target;

  get = name: env'."${prefix}_${name}";
  set = name: value: {"${prefix}_${name}" = value;};
  tag = name: "${target}-${name}";

  env' =
    {inherit target prefix get set tag;}
    // set "DATA_DIR" "${HOME}/data/${target}"
    // set "SECRETS_FILE" "${PRIVATE}/${target}.env"
    // set "API_URL" "http://100.90.252.109:8888"
    // set "BIND_ADDRESS" "100.90.252.109"
    // set "LLM_BASE_URL" "http://100.76.128.70:20128/v1"
    // set "LLM_MODEL" "auto/best-fast"
    // set "REFLECT_LLM_MODEL" "auto/best-chat"
    // set "API_WORKER_ID" "Hindsight-Victus"
    // set "COMPOSE_PROJECT" target
    // set "CONTAINER_NAME" target;
in {
  description = "Hindsight Memory Service";
  env = recursiveUpdate env env';
}
