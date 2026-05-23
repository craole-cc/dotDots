{dots, ...}: let
  description = "Hermes Minimal";
  inherit (dots) pkgs inputPkgs;

  llms = inputPkgs "llm-agents";
in {
  inherit description;

  packages = (
    []
    ++ (with pkgs; [
      nodejs_22
      ollama
    ])
    ++ (with llms; [
      hermes-agent
    ])
  );

  env = {
    OLLAMA_HOST = "http://127.0.0.1:11434";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";

    OPENAI_API_BASE = "http://127.0.0.1:11434/v1";
    OPENAI_BASE_URL = "http://127.0.0.1:11434/v1";

    HERMES_INFERENCE_MODEL = "qwen2.5-coder:3b";
  };

  shellHook = ''
    gum style --italic --bold "Hermes Minimal"
    printf '%s\n' "Telegram stays as the front end for Hermes."
    printf '%s\n' "Local backend: Ollama at %s" "$OPENAI_API_BASE"
    printf '%s\n' "Default local model: %s""$OLLAMA_DEFAULT_MODEL"
    printf '%s\n' "Start backend: ollama serve"
    printf '%s\n' "Check models: curl %s/models"  "$OPENAI_API_BASE"
    printf '%s\n' "Chat locally: hermes chat"
  '';
}
