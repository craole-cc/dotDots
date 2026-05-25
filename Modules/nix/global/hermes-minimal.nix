{dots, ...}: let
  description = "Hermes Minimal";

  inherit (dots) pkgs inputPkgs;
  llms = inputPkgs "llm-agents";
  mkBin = pkgs.writeShellScriptBin;

  # ── Helpers (shell fragments) ────────────────────────────────────────────────

  set-term = ''
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      terminal="${pkgs.foot}/bin/foot"
    elif [ -n "$DISPLAY" ]; then
      terminal="${pkgs.xterm}/bin/xterm"
    else
      gum log --level error "No display server detected."
      exit 1
    fi
  '';

  run-in-term = cmd: ''
    $terminal -e bash -lc '${cmd}; exec bash' </dev/null >/dev/null 2>&1 &
    disown $!
  '';

  check-ollama = ''curl -sf "$OLLAMA_HOST" > /dev/null 2>&1'';
  check-hermes = ''pgrep -f 'hermes gateway run' > /dev/null 2>&1'';

  kill-ollama = ''pkill -f 'ollama serve' '';
  kill-hermes = ''pkill -f 'hermes gateway run' '';

  # ── Scripts ──────────────────────────────────────────────────────────────────

  ollama-models = mkBin "ollama-models" ''
    if ! ${check-ollama}; then
      gum log --level error "Ollama not reachable at $OLLAMA_HOST — is it running?"
      exit 1
    fi
    gum log --level info "Models available at $OLLAMA_HOST"
    curl -sf "$OPENAI_API_BASE/models" \
      | jq -r '.data[].id' \
      | while read -r model; do gum style "  • $model"; done
  '';

  ollama-serve = mkBin "ollama-serve" ''
    if ${check-ollama}; then
      gum log --level warn "Ollama already running at $OLLAMA_HOST — skipping."
      exit 0
    fi
    ${set-term}
    ${run-in-term "ollama serve"}
    gum log --level info "Ollama launched via $terminal."
    for i in $(seq 1 10); do
      ${check-ollama} && exit 0
      sleep 0.5
    done
    gum log --level error "Ollama launched but not reachable at $OLLAMA_HOST after 5s."
    exit 1
  '';

  ollama-stop = mkBin "ollama-stop" ''
    if ! ${check-ollama}; then
      gum log --level warn "Ollama is not running."
      exit 0
    fi
    ${kill-ollama} \
      && gum log --level info "Ollama stopped." \
      || gum log --level error "Failed to stop Ollama."
  '';

  hermes-serve = mkBin "hermes-serve" ''
    if ${check-hermes}; then
      gum log --level warn "Hermes Gateway already running — skipping."
      exit 0
    fi
    ${set-term}
    ${run-in-term "hermes gateway run"}
    gum log --level info "Hermes Gateway launched via $terminal."
    for i in $(seq 1 20); do
      ${check-hermes} && exit 0
      sleep 0.5
    done
    gum log --level error "Hermes Gateway launched but process not found after 10s."
    exit 1
  '';

  hermes-stop = mkBin "hermes-stop" ''
    if ! ${check-hermes}; then
      gum log --level warn "Hermes Gateway is not running."
      exit 0
    fi
    ${kill-hermes} \
      && gum log --level info "Hermes Gateway stopped." \
      || gum log --level error "Failed to stop Hermes Gateway."
  '';

  start-services = mkBin "start-services" ''
    if ! ${check-ollama}; then
      gum confirm "Start Ollama?" && ollama-serve || true
    fi
    if ! ${check-hermes}; then
      gum confirm "Start Hermes Gateway?" && hermes-serve || true
    fi
  '';

  stop-services = mkBin "stop-services" ''
    if ${check-ollama}; then
      gum confirm "Stop Ollama?" && ollama-stop || true
    fi
    if ${check-hermes}; then
      gum confirm "Stop Hermes Gateway?" && hermes-stop || true
    fi
  '';
in {
  inherit description;

  # ── Packages ─────────────────────────────────────────────────────────────────

  packages =
    (with pkgs; [
      nodejs_22
      ollama
      jq
      ollama-models
      ollama-serve
      ollama-stop
      hermes-serve
      hermes-stop
      start-services
      stop-services
    ])
    ++ (with llms; [hermes-agent]);

  # ── Environment ──────────────────────────────────────────────────────────────

  env = {
    OLLAMA_HOST = "http://127.0.0.1:11434";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";

    OPENAI_API_BASE = "http://127.0.0.1:11434/v1";
    OPENAI_BASE_URL = "http://127.0.0.1:11434/v1";

    HERMES_INFERENCE_MODEL = "qwen2.5-coder:3b";
  };

  # ── Shell hook ───────────────────────────────────────────────────────────────

  shellHook = ''
    gum style --bold --italic "${description}"

    ollama-models || true

    if ${check-hermes}; then
      gum style --border rounded --padding "0 1" --align left \
        "Ollama" \
        "  ollama-serve           start Ollama" \
        "  ollama-stop            stop Ollama" \
        "  ollama-models          list available models" \
        "  ollama run <model>     load a model interactively" \
        "  ollama pull <model>    download a new model" \
        "" \
        "Hermes  (gateway is running)" \
        "  hermes chat            chat locally in the terminal" \
        "  Telegram               message your bot directly" \
        "  hermes-stop            stop Hermes Gateway" \
        "" \
        "Services" \
        "  start-services         start missing services" \
        "  stop-services          stop running services"
    else
      gum style --border rounded --padding "0 1" --align left \
        "Ollama" \
        "  ollama-serve           start Ollama" \
        "  ollama-stop            stop Ollama" \
        "  ollama-models          list available models" \
        "  ollama run <model>     load a model interactively" \
        "  ollama pull <model>    download a new model" \
        "" \
        "Hermes  (gateway not running — run: hermes setup)" \
        "  hermes-serve           start Hermes Gateway" \
        "  hermes chat            chat locally in the terminal" \
        "" \
        "Services" \
        "  start-services         start missing services" \
        "  stop-services          stop running services"
    fi

    start-services
  '';
}
