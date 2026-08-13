{
  helpers,
  runtimes,
  service-builder,
  ...
}: rec {
  inherit (helpers) log mkBin;
  inherit (service-builder) mkRequire;

  check-ollama-model = ''
    curl -sf "$OLLAMA_LOCALHOST/api/tags"       | jq -e --arg model "$OLLAMA_DEFAULT_MODEL"         'any(.models[]?; .name == $model)'       >/dev/null
  '';

  ollama-models = mkBin "ollama-models" runtimes.default ''
        ${mkRequire {
      check = "ollama-status >/dev/null 2>&1";
      msg = "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?";
    }}

        ${log} info "Models available at $OLLAMA_LOCALHOST"

        models="$(curl -sf "$OLLAMA_LOCALHOST/api/tags" | jq -r '.models[]?.name')"

        if [ -z "$models" ]; then
          ${log} warn "No models installed. Try: ollama pull $OLLAMA_DEFAULT_MODEL"
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
      msg = "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?";
    }}

    ${mkRequire {
      check = check-ollama-model;
      msg = "Model '$OLLAMA_DEFAULT_MODEL' is not installed.";
      action = ''
        ${log} info "Run: ollama pull $OLLAMA_DEFAULT_MODEL"
        exit 1
      '';
    }}

    ollama run "$OLLAMA_DEFAULT_MODEL"
  '';
}
