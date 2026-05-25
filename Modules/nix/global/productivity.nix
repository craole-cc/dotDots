{dots, ...}: let
  description = "AI Assistance";
  name = "ai";

  inherit (dots) pkgs inputPkgs;
  llm = inputPkgs "llm-agents";
  mkBin = pkgs.writeShellScriptBin;
  log = ''gum log --level'';
  confirm = ''gum confirm'';

  set-term = ''
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      terminal="${pkgs.foot}/bin/foot"
    elif [ -n "$DISPLAY" ]; then
      terminal="${pkgs.xterm}/bin/xterm"
    else
      ${log} error "No display server detected."
      exit 1
    fi
  '';

  run = cmd: ''
    $terminal -e bash -lc '${cmd}; exec bash' </dev/null >/dev/null 2>&1 &
    disown $!
  '';

  kill-hermes = "pkill -f 'hermes gateway run'";
  kill-ollama = "pkill -f 'ollama serve'";

  check-hermes = ''pgrep -f 'hermes gateway run' > /dev/null 2>&1'';
  check-ollama = ''curl -sf "$OLLAMA_HOST" > /dev/null 2>&1'';
  check-ollama-models = mkBin "ollama-models" ''
    if ! ${check-ollama}; then
      ${log} error "Ollama not reachable at $OLLAMA_HOST - is it running?"
      exit 1
    fi

    ${log} info "Models available at $OLLAMA_HOST"
    curl -sf "$OLLAMA_HOST/api/tags" \
      | jq -r '.models[].name' \
      | while read -r model; do gum style "  • $model"; done
  '';

  start-hermes = mkBin "hermes-start" ''
    if ${check-hermes}; then
      ${log} warn "Hermes Gateway already running - skipping."
      exit 0
    fi

    ${confirm} "Start Hermes Gateway?" || exit 0

    ${set-term}
    ${run "hermes gateway run"}
    ${log} info "Hermes Gateway launched via '$(basename $terminal)'."

    sleep 1
    if ${check-hermes}; then
      ${log} info "Hermes Gateway is running."
    else
      ${log} warn "Hermes Gateway not yet detected - it may still be starting."
    fi
  '';

  start-ollama = mkBin "ollama-start" ''
    if ${check-ollama}; then
      ${log} warn "Ollama already running at $OLLAMA_HOST - skipping."
      exit 0
    fi

    ${confirm} "Start Ollama?" || exit 0

    ${set-term}
    ${run "ollama serve"}
    ${log} info "Ollama launched via '$(basename "$terminal")'."

    sleep 1
    if ${check-ollama}; then
      ${log} info "Ollama is reachable at '$OLLAMA_HOST'."
    else
      ${log} warn "Ollama not yet reachable - it may still be starting."
    fi
  '';

  stop-ollama = mkBin "ollama-stop" ''
    if ! ${check-ollama}; then
      ${log} warn "Ollama is not running."
      exit 0
    fi

    ${confirm} "Stop Ollama?" || exit 0

    if ${kill-ollama}; then
      ${log} info "Ollama stopped."
    else
      ${log} error "Failed to stop Ollama."
    fi
  '';

  stop-hermes = mkBin "hermes-stop" ''
    if ! ${check-hermes}; then
      ${log} warn "Hermes Gateway is not running."
      exit 0
    fi

    ${confirm} "Stop Hermes Gateway?" || exit 0

    if ${kill-hermes}; then
      ${log} info "Hermes Gateway stopped."
    else
      ${log} error "Failed to stop Hermes Gateway."
    fi
  '';

  start-all = mkBin "start-${name}" ''
    ollama-start
    hermes-start
  '';

  stop-all = mkBin "stop-${name}" ''
    ollama-stop
    hermes-stop
  '';

  help-ollama = mkBin "ollama-help" ''
    if ${check-ollama}; then
      gum style \
        "Ollama" \
        "  ollama-models          list available models" \
        "  ollama-stop            stop Ollama" \
        "  ollama run <model>     chat with a model" \
        "  ollama pull <model>    download a model"
    else
      gum style \
        "Ollama [not running]" \
        "  ollama-start           start Ollama" \
        "  ollama run <model>     chat with a model" \
        "  ollama pull <model>    download a model" \
        "  ollama help            more information"
    fi
  '';

  help-hermes = mkBin "hermes-help" ''
    if ${check-hermes}; then
      gum style \
        "Hermes  (gateway is running)" \
        "  hermes chat            chat locally in the terminal" \
        "  Telegram               message your bot directly" \
        "  hermes-stop            stop Hermes Gateway"
    else
      gum style \
        "Hermes  (gateway not running - run: hermes setup)" \
        "  hermes-start           start Hermes Gateway" \
        "  hermes chat            chat locally in the terminal"
    fi
  '';

  help-services = mkBin "help-services" ''
    gum style \
      "Services" \
      "  start-${name}         start missing services" \
      "  stop-${name}          stop running services"
  '';
in {
  inherit description;
  packages =
    (with pkgs; [
      nodejs_22
      ollama
      jq

      start-all
      start-hermes
      start-ollama

      stop-all
      stop-hermes
      stop-ollama

      check-ollama-models

      help-ollama
      help-hermes
      help-services
    ])
    ++ (with llm; [hermes-agent]);

  env = {
    OLLAMA_HOST = "http://127.0.0.1:11434";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";
    OLLAMA_BASE_URL = "http://127.0.0.1:11434/v1";

    HERMES_INFERENCE_MODEL = "qwen2.5-coder:3b";
  };

  shellHook = ''
    gum style --bold --italic "${description}"
    gum style --border rounded --padding "0 1" --align left \
      "$(ollama-help)" "" \
      "$(hermes-help)" "" \
      "$(help-services)"
    start-${name}
  '';
}
