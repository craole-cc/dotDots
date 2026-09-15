# environment/default.nix
{
  lix,
  env,
  cfg,
  ...
}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.strings.transformation) toUpper;
  inherit (cfg.hindsight) image llm ports;

  target = env.name or "hindsight";
  prefix = toUpper target;

  tag = name: "${target}-${name}";
  set = name: value: {"${prefix}_${name}" = value;};
  get = name: vars."${prefix}_${name}";

  vars =
    set "API_URL" "http://${cfg.bindAddress}:${toString ports.api}"
    // set "BIND_ADDRESS" cfg.bindAddress
    // set "IMAGE" image
    // set "LLM_BACKEND" llm.backend
    // set "LLM_BASE_URL" llm.baseUrl
    // set "LLM_MODEL" llm.model
    // set "REFLECT_LLM_MODEL" llm.reflectModel
    // set "COMPOSE_PROJECT" "hindsight-${cfg.instance}"
    // set "CONTAINER_NAME" "hindsight-${cfg.instance}";
in {
  title = "Hindsight Memory Service";
  env = recursiveUpdate env vars;
  lib = {inherit target prefix get set tag;};
}
