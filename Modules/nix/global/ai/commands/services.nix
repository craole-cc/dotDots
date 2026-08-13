{
  prepare-hermes-messaging,
  prepare-whatsapp-bridge,
  runtimes,
  ...
}: {
  ollama = {
    title = "Ollama";
    process = "ollama serve";
    runtime = runtimes.ollama;

    check = ''
      curl -sf "$OLLAMA_LOCALHOST/api/tags" >/dev/null 2>&1
    '';

    wait.label = "Ollama is reachable at $OLLAMA_LOCALHOST.";

    help = {
      common = [
        "ollama-status           Check Ollama status"
        "ollama-run <model>      Chat with a specific model"
        "ollama-pull <model>     Download a model"
      ];
      running = [
        "ollama-stop             Stop Ollama"
        "ollama-models           List available models"
        "ollama-chat             Chat with $OLLAMA_DEFAULT_MODEL"
      ];
      stopped = [
        "ollama-start            Start Ollama"
      ];
    };
  };

  hermes = {
    title = "Hermes";
    process = "hermes.*gateway";
    command = ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes gateway run
    '';
    runtime = runtimes.hermes;

    wait.label = "Hermes gateway is open and allowing messaging.";

    help = {
      common = [
        "hermes-status           Check Hermes Gateway status"
        "hermes-whatsapp         Pair/configure WhatsApp bridge"
        "hermes-tui              Open Hermes TUI with default profile"
        "hermes-dev              Open Hermes TUI with the dev profile"
        "hermes-research         Open Hermes TUI with the research profile"
        "hermes-writing          Open Hermes TUI with the writing profile"
        "hermes-lab              Open Hermes TUI with the lab profile"
      ];
      running = [
        "hermes-stop             Stop Hermes Gateway"
      ];
      stopped = [
        "hermes-start            Start Hermes Gateway"
        "hermes-setup            Setup Hermes, if not already done"
      ];
    };
  };
}
