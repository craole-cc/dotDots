{
  # args,
  env,
  cmds,
  ...
}: let
  inherit (env) LOCALHOST;
  inherit (cmds) helpers runtimes service-builder;
  inherit (helpers) log mkBin;
  inherit (service-builder) mkRequire;

  OLLAMA_PORT = "11434";
  OLLAMA_LOCALHOST = "${LOCALHOST}:${OLLAMA_PORT}";
  OLLAMA_BASE_URL = "${OLLAMA_LOCALHOST}/v1";
  OLLAMA_TAGS = "${OLLAMA_LOCALHOST}/api/tags";
  OLLAMA_CONTEXT_LENGTH = "64000";
  OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";
  AUTO_START = 0;
  STARTUP_TIMEOUT = 15;

  check-ollama-model = ''
    curl -sf "${OLLAMA_TAGS}" | jq -e --arg model "${OLLAMA_DEFAULT_MODEL}" 'any(.models[]?; .name == $model)' >/dev/null
  '';

  ollama-models = mkBin "ollama-models" runtimes.default ''
        ${mkRequire {
      check = "ollama-status >/dev/null 2>&1";
      msg = "Ollama not reachable at ${OLLAMA_LOCALHOST} - is it running?";
    }}

        ${log} info "Models available at ${OLLAMA_LOCALHOST}"

        models="$(curl -sf "${OLLAMA_TAGS}" | jq -r '.models[]?.name')"

        if [ -z "$models" ]; then
          ${log} warn "No models installed. Try: ollama pull ${OLLAMA_DEFAULT_MODEL}"
          exit 0
        fi

        printf '%s
    ' "$models" | while read -r model; do
          gum style "  • $model"
        done
  '';

  ollama-chat = mkBin "ollama-chat" (runtimes.default ++ runtimes.ollama) ''
    ${mkRequire {
      check = "ollama-status >/dev/null 2>&1";
      msg = "Ollama not reachable at ${OLLAMA_LOCALHOST} - is it running?";
    }}

    ${mkRequire {
      check = check-ollama-model;
      msg = "Model '${OLLAMA_DEFAULT_MODEL}' is not installed.";
      action = ''
        ${log} info "Run: ollama pull ${OLLAMA_DEFAULT_MODEL}"
        exit 1
      '';
    }}

    ollama run "${OLLAMA_DEFAULT_MODEL}"
  '';
in {
  env = {
    inherit
      AUTO_START
      OLLAMA_BASE_URL
      OLLAMA_CONTEXT_LENGTH
      OLLAMA_DEFAULT_MODEL
      OLLAMA_LOCALHOST
      OLLAMA_PORT
      STARTUP_TIMEOUT
      ;
  };

  commands = {
    inherit check-ollama-model ollama-chat ollama-models;
  };
}
