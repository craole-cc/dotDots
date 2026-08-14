args: let
  LOCALHOST = "http://127.0.0.1";
  OLLAMA_LOCALHOST = "http://127.0.0.1:11434";
  OLLAMA_BASE_URL = "${OLLAMA_LOCALHOST}/v1";
  OLLAMA_CONTEXT_LENGTH = "64000";
  OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";

  AUTO_START = 0;
  STARTUP_TIMEOUT = 15;
in {
  description = "AI Assistance";
  env = {
    inherit
      LOCALHOST
      OLLAMA_LOCALHOST
      OLLAMA_BASE_URL
      OLLAMA_CONTEXT_LENGTH
      OLLAMA_DEFAULT_MODEL
      AUTO_START
      STARTUP_TIMEOUT
      ;
  };

  shellHook = ''
    if [ -t 1 ]; then
      case "''${AUTO_START:-1}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
}
