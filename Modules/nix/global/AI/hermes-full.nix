{dots, ...}: let
  description = "Hermes Full";
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
    gum style --italic --bold "Hermes Full"
    printf '%s\n' "Hermes + Ollama + Telegram."
    printf '%s\n' "Default Hermes provider: Ollama (free/local)."
    printf '%s\n' "Switch Hermes providers with: hermes model"
    printf '%s\n' "Use OpenAI/Codex when you want, Ollama when you want free local runs."
    printf '%s\n' "Telegram stays as the front end; Ollama is just the backend model."
    printf '%s\n' "Start Ollama with: ollama serve"
  '';
}
