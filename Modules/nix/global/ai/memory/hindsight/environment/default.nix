# environment/default.nix
{
  lix,
  env,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) toUpper;

  target = env.name or "hindsight";
  prefix = toUpper target;

  tag = name: "${target}-${name}";
  set = name: value: {"${prefix}_${name}" = value;};
  get = name: vars."${prefix}_${name}";

  vars =
    set "API_URL" "http://127.0.0.1:8888"
    // set "BIND_ADDRESS" "127.0.0.1"
    // set "IMAGE" "ghcr.io/vectorize-io/hindsight:0.9.2"
    // set "LLM_BASE_URL" "https://openrouter.ai/api/v1"
    // set "LLM_MODEL" "openrouter/free"
    // set "REFLECT_LLM_MODEL" "openrouter/free"
    // set "COMPOSE_PROJECT" target
    // set "CONTAINER_NAME" target;
in {
  title = "Hindsight Memory Service";
  env = recursiveUpdate env vars;
  lib = {inherit target prefix get set tag;};
}
