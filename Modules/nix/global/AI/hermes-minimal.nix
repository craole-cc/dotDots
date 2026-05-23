{dots, ...}: let
  description = "Hermes Minimal";
  inherit (dots) inputPkgs pkgs;

  llms = inputPkgs "llm-agents";
in {
  inherit description;

  packages = [
    pkgs.ollama
    llms.hermes-agent
  ];

  env = {
    OLLAMA_HOST = "http://127.0.0.1:11434";
  };

  shellHook = ''
    gum style --italic --bold "Hermes Minimal"
    printf '%s\n' "Local-only Hermes: Telegram + Ollama."
    printf '%s\n' "Default Hermes provider: Ollama (free/local)."
    printf '%s\n' "Telegram stays as the front end; Ollama is only the inference backend."
    printf '%s\n' "Start Ollama with: ollama serve"
    printf '%s\n' "Choose a model with: hermes model"
  '';
}
