{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) toUpper;

  HOME = env.HOME or "/home/craole";
  PRIVATE = env.PRIVATE or "${HOME}/Private";

  name = "hindsight";
  prefix = toUpper name;

  env' = {
    inherit name prefix;
    "${prefix}_DATA_DIR" = "${HOME}/data/${name}"; #TODO: Should we use XDG_DATA_HOME instead of ${HOME}/data?
    "${prefix}_SECRETS_FILE" = "${PRIVATE}/${name}.env";
    "${prefix}_API_URL" = "http://100.90.252.109:8888";
    "${prefix}_BIND_ADDRESS" = "100.90.252.109";
    "${prefix}_LLM_BASE_URL" = "http://100.76.128.70:20128/v1";
    "${prefix}_LLM_MODEL" = "auto/best-fast";
    "${prefix}_REFLECT_LLM_MODEL" = "auto/best-chat";
    "${prefix}_API_WORKER_ID" = "Hindsight-Victus";
    "${prefix}_COMPOSE_PROJECT" = name;
    "${prefix}_CONTAINER_NAME" = name;
  };
in {
  description = "Hindsight Memory Service";
  env = recursiveUpdate env env';
}
