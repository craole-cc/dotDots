{dots, ...}: let
  description = "Hermes Minimal";
  inherit (dots) pkgs inputPkgs;

  llms = inputPkgs "llm-agents";
in {
  inherit description;

  packages = with pkgs; [
    nodejs_22
    ollama
  ] ++ (with llms; [
    hermes-agent
  ]);

  env = {
    HERMES_INFERENCE_PROVIDER = "ollama";
    HERMES_INFERENCE_MODEL = "qwen2.5-coder:3b";
    OLLAMA_HOST = "http://127.0.0.1:11434";
  };

  shellHook = ''
    gum style --italic --bold "Hermes Minimal"
    printf '%s\n' "Telegram stays as the front end for Hermes."
    printf '%s\n' "Default provider: Ollama (free/local)."
    printf '%s\n' "Default model: qwen2.5-coder:3b"
    printf '%s\n' "Start the backend first: ollama serve"
    printf '%s\n' "If needed, pull the model first: ollama pull qwen2.5-coder:3b"
    printf '%s\n' "Then launch Hermes: hermes chat"
    printf '%s\n' "Override at runtime: hermes --provider ollama --model <name> chat"
  '';
}
