{dots, ...}: let
  inherit (dots) pkgs inputPkgs;
  hermes = (inputPkgs "llm-agents").hermes-agent;

  description = "AI Assistance";

  env = {
    OLLAMA_LOCALHOST = "http://127.0.0.1:11434";
    OLLAMA_BASE_URL = "$OLLAMA_LOCALHOST/v1";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";
    PRODUCTIVITY_AUTO_START = "1";
    PRODUCTIVITY_STARTUP_TIMEOUT = "15";
  };

  packages =
    (with pkgs; [curl gum jq nodejs_22 ollama])
    ++ [hermes]
    ++ (let
      mkBin = name: runtimeInputs: text:
        pkgs.writeShellApplication {inherit name runtimeInputs text;};

      common-runtime = with pkgs; [coreutils gum procps];
      api-runtime = with pkgs; [curl jq];
      ollama-runtime = with pkgs; [ollama];
      hermes-runtime = [hermes];

      log = "gum log --level";
      confirm = "gum confirm";
      checker = pattern: ''pgrep -f "${pattern}" > /dev/null 2>&1'';
      killer = pattern: ''pkill -f "${pattern}" > /dev/null 2>&1'';

      set-terminal = ''
        case "$XDG_SESSION_TYPE" in
          wayland) terminal="${pkgs.foot}/bin/foot" ;;
          *)
            case "$DISPLAY" in
              "")
                ${log} error "No display server detected."
                exit 1
              ;;
              *) terminal="${pkgs.xterm}/bin/xterm" ;;
            esac
          ;;
        esac
      '';

      run = cmd: ''
        # shellcheck disable=SC2016
        "$terminal" -e sh -lc '${cmd}
        exec "''${SHELL:-/bin/sh}"' </dev/null >/dev/null 2>&1 &
      '';

      wait-until = check: label: ''
        timeout="''${PRODUCTIVITY_STARTUP_TIMEOUT:-15}"
        elapsed=0
        while [ "$elapsed" -lt "$timeout" ]; do
          if ${check}; then
            ${log} info "${label}"
            exit 0
          fi
          sleep 1
          elapsed=$((elapsed + 1))
        done
        ${log} warn "Timed out waiting for ${label}."
        exit 1
      '';

      #~@ Ollama
      kill-ollama = killer "ollama serve";
      check-ollama = checker "ollama serve";
      check-ollama-model = ''curl -sf "$OLLAMA_LOCALHOST/api/tags" | jq -e --arg model "$OLLAMA_DEFAULT_MODEL" 'any(.models[]?; .name == $model)' > /dev/null'';

      show-ollama-models = mkBin "ollama-models" (common-runtime ++ api-runtime) ''
        if ${check-ollama}; then :; else
          ${log} error "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"
          exit 1
        fi

        ${log} info "Models available at $OLLAMA_LOCALHOST"
        models="$(curl -sf "$OLLAMA_LOCALHOST/api/tags" | jq -r '.models[]?.name')"

        if [ -z "$models" ]; then
          ${log} warn "No models installed. Try: ollama pull $OLLAMA_DEFAULT_MODEL"
          exit 0
        fi

        printf '%s\n' "$models" | while read -r model; do
          gum style "  • $model"
        done
      '';

      start-ollama =
        mkBin "ollama-start" (
          common-runtime ++ api-runtime ++ ollama-runtime
        ) ''
          if ${check-ollama}; then
            ${log} warn "Ollama already running at $OLLAMA_LOCALHOST - skipping."
            exit 0
          fi
          ${confirm} "Start Ollama?" || exit 0
          ${set-terminal}
          ${run "ollama serve"}
          ${log} info "Ollama launched via '$(basename "$terminal")'."
          ${wait-until check-ollama "Ollama is reachable at '$OLLAMA_LOCALHOST'."}
        '';

      stop-ollama =
        mkBin "ollama-stop" (
          common-runtime ++ api-runtime
        ) ''
          if ${check-ollama}; then :; else
            ${log} warn "Ollama is not running."
            exit 0
          fi
          force=0
          for arg in "$@"; do
            case "$arg" in --force) force=1 ;; esac
          done
          if [ "$force" = "0" ]; then
            ${confirm} "Stop Ollama?" </dev/tty || exit 0
          fi
          if ${kill-ollama}; then
            ${log} info "Ollama stopped."
          else
            ${log} error "Failed to stop Ollama."
          fi
        '';

      chat-with-ollama = mkBin "ollama-chat" (common-runtime ++ api-runtime ++ ollama-runtime) ''
        if ! ${check-ollama}; then
          ${log} error "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"
          exit 1
        fi
        if ! ${check-ollama-model}; then
          ${log} error "Model '$OLLAMA_DEFAULT_MODEL' is not installed."
          ${log} info "Run: ollama pull $OLLAMA_DEFAULT_MODEL"
          exit 1
        fi
        ollama run "$OLLAMA_DEFAULT_MODEL"
      '';

      #~@ Hermes
      check-hermes = checker "hermes gateway run";
      kill-hermes = killer "hermes gateway run";

      start-hermes =
        mkBin "hermes-start" (
          common-runtime ++ api-runtime ++ hermes-runtime
        ) ''
          if ${check-hermes}; then
            ${log} warn "Hermes Gateway already running - skipping."
            exit 0
          fi
          ${set-terminal}
          ${confirm} "Start Hermes Gateway?" || exit 0
          ${run "hermes gateway run"}
          ${log} info "Hermes Gateway launched via '$(basename "$terminal")'."
          ${wait-until check-hermes "Hermes Gateway is running."}
        '';

      stop-hermes = mkBin "hermes-stop" common-runtime ''
        if ${check-hermes}; then :; else
          ${log} warn "Hermes Gateway is not running."
          exit 0
        fi
        force=0
        for arg in "$@"; do
          case "$arg" in --force) force=1 ;; esac
        done
        if [ "$force" = "0" ]; then
          ${confirm} "Stop Hermes Gateway?" </dev/tty || exit 0
        fi
        if ${kill-hermes}; then
          ${log} info "Hermes Gateway stopped."
        else
          ${log} error "Failed to stop Hermes Gateway."
        fi
      '';

      chat-with-hermes = mkBin "hermes-chat" hermes-runtime ''
        hermes chat
      '';

      #~@ All services
      start-all = mkBin "start-services" [start-ollama start-hermes] ''
        ollama-start
        hermes-start
      '';

      stop-all = mkBin "stop-services" [stop-ollama stop-hermes] ''
        ollama-stop "$@"
        hermes-stop "$@"
      '';

      #~@ Help
      help-ollama = mkBin "ollama-help" (common-runtime ++ api-runtime) ''
        if ${check-ollama}; then
          gum style \
            "Ollama (server initiated)" \
            "  ollama-stop            stop Ollama" \
            "  ollama-models          list available models" \
            "  ollama-chat            chat with $OLLAMA_DEFAULT_MODEL" \
            "  ollama run <model>     chat with a specific model" \
            "  ollama pull <model>    download a model"
        else
          gum style \
            "Ollama" \
            "  ollama-start           start Ollama" \
            "  ollama run <model>     chat with a specific model" \
            "  ollama pull <model>    download a model"
        fi
      '';

      help-hermes = mkBin "hermes-help" common-runtime ''
        if ${check-hermes}; then
          gum style \
            "Hermes (gateway initiated)" \
            "  Messaging via Telegram and other configured portals" \
            "  hermes-stop            stop Hermes Gateway" \
            "  hermes chat            chat locally in the terminal"
        else
          gum style \
            "Hermes" \
            "  hermes-start           start Hermes Gateway" \
            "  hermes setup           setup Hermes if not already done" \
            "  hermes chat            chat locally in the terminal"
        fi
      '';

      help-services = mkBin "help-services" [pkgs.gum] ''
        gum style \
          "All Services" \
          "  start-services         start missing services" \
          "  stop-services          stop running services"
      '';

      show-help = let
        mkSection = cmd: ''printf "%s\n\n" "$(${cmd})"'';
      in
        mkBin "show-help" [pkgs.gum help-ollama help-hermes help-services] ''
          gum style --border rounded --padding "0 1" --align left "$(
            gum style --bold --italic "${description}"
            ${mkSection "ollama-help"}
            ${mkSection "hermes-help"}
            ${mkSection "help-services"}
          )"
        '';
    in [
      start-all
      start-hermes
      start-ollama

      stop-all
      stop-hermes
      stop-ollama

      show-ollama-models
      chat-with-ollama
      chat-with-hermes

      help-ollama
      help-hermes
      help-services
      show-help
    ]);

  shellHook = ''
    if [ -t 1 ]; then
      case "''${PRODUCTIVITY_AUTO_START:-1}" in
        1) start-services ;;
      esac
      show-help
    fi
  '';
in {inherit description env packages shellHook;}
