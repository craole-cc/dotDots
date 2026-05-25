{dots, ...}: let
  inherit (dots) pkgs inputPkgs;

  description = "AI Assistance";

  env = {
    OLLAMA_LOCALHOST = "http://127.0.0.1:11434";
    OLLAMA_BASE_URL = "$OLLAMA_LOCALHOST/v1";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";
  };

  packages =
    (with pkgs; [
      gum
      jq
      nodejs_22
      ollama
    ])
    ++ (with (inputPkgs "llm-agents"); [hermes-agent])
    ++ (let
      mkBin = pkgs.writeShellScriptBin;
      log = ''gum log --level'';
      confirm = ''gum confirm'';

      set-terminal = ''
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
      check-ollama = ''curl -sf "$OLLAMA_LOCALHOST" > /dev/null 2>&1'';
      check-ollama-models = mkBin "ollama-models" ''
        if ! ${check-ollama}; then
          ${log} error "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"
          exit 1
        fi

        ${log} info "Models available at $OLLAMA_LOCALHOST"
        curl -sf "$OLLAMA_LOCALHOST/api/tags" \
          | jq -r '.models[].name' \
          | while read -r model; do gum style "  • $model"; done
      '';

      start-hermes = mkBin "hermes-start" ''
        ${set-terminal}

        if ${check-hermes}; then
          ${log} warn "Hermes Gateway already running - skipping."
          exit 0
        fi

        ${confirm} "Start Hermes Gateway?" || exit 0

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
          ${log} warn "Ollama already running at $OLLAMA_LOCALHOST - skipping."
          exit 0
        fi

        ${confirm} "Start Ollama?" || exit 0

        ${set-terminal}
        ${run "ollama serve"}
        ${log} info "Ollama launched via '$(basename "$terminal")'."

        sleep 1
        if ${check-ollama}; then
          ${log} info "Ollama is reachable at '$OLLAMA_LOCALHOST'."
        else
          ${log} warn "Ollama not yet reachable - it may still be starting."
        fi
      '';

      ollama-chat = mkBin "ollama-chat" ''
        if ! ${check-ollama}; then
          ${log} error "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"
          exit 1
        fi
        ollama run "$OLLAMA_DEFAULT_MODEL"
      '';

      stop-ollama = mkBin "ollama-stop" ''
        if ! ${check-ollama}; then
          ${log} warn "Ollama is not running."
          exit 0
        fi

        if [ "$1" != "--force" ]; then
          ${confirm} "Stop Ollama?" </dev/tty || exit 0
        fi

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

        if [ "$1" != "--force" ]; then
          ${confirm} "Stop Hermes Gateway?" </dev/tty || exit 0
        fi

        if ${kill-hermes}; then
          ${log} info "Hermes Gateway stopped."
        else
          ${log} error "Failed to stop Hermes Gateway."
        fi
      '';

      stop-all = mkBin "stop-services" ''
        ollama-stop "$@"
        hermes-stop "$@"
      '';

      start-all = mkBin "start-services" ''
        ollama-start
        hermes-start
      '';

      help-ollama = mkBin "ollama-help" ''
        if ${check-ollama}; then
          gum style \
            "Ollama (server initiated)" \
            "  ollama-stop            stop Ollama" \
            "  ollama-models          list available models" \
            "  ollama run <model>     chat with a model" \
            "  ollama pull <model>    download a model" \
            "  ollama-chat            chat with $OLLAMA_DEFAULT_MODEL"
        else
          gum style \
            "Ollama" \
            "  ollama-start           start Ollama" \
            "  ollama run <model>     chat with a model" \
            "  ollama pull <model>    download a model"
        fi
      '';

      help-hermes = mkBin "hermes-help" ''
        if ${check-hermes}; then
          gum style \
            "Hermes (gateway initiated)" \
            "  Gateway enables messaging via configured portals" \
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

      help-services = mkBin "help-services" ''
        gum style \
          "Services" \
          "  start-services           start missing services" \
          "  stop-services            stop running services"
      '';

      show-help = let
        mkSection = cmd: ''printf "%s\n\n" "$(${cmd})"'';
      in
        mkBin "show-help" ''
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

      check-ollama-models
      ollama-chat

      help-ollama
      help-hermes
      help-services
      show-help
    ]);

  shellHook = ''
    # trap '
    #   stop-services --force
    # ' EXIT

    start-services
    show-help
  '';
in {inherit description env packages shellHook;}
