{dots, ...}: let
  inherit (dots) pkgs lib llm;
  inherit (lib.attrsets) attrNames attrValues mapAttrs;
  inherit (lib.lists) concatLists flatten;
  inherit (lib.strings) concatStringsSep concatMapStringsSep escapeShellArg;

  description = "AI Assistance";

  #|---------------------------------------------------------|
  #| Environment --------------------------------------------|
  #|---------------------------------------------------------|

  env = rec {
    OLLAMA_LOCALHOST = "http://127.0.0.1:11434";
    OLLAMA_BASE_URL = "${OLLAMA_LOCALHOST}/v1";
    OLLAMA_CONTEXT_LENGTH = "64000";
    OLLAMA_DEFAULT_MODEL = "qwen2.5-coder:3b";

    AUTO_START = "1";
    STARTUP_TIMEOUT = "15";
  };

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  packages = let
    mkBin = name: runtimeInputs: text:
      pkgs.writeShellApplication {
        inherit name runtimeInputs text;
      };

    runtimes = let
      common = with pkgs; [coreutils gum procps];
      api = with pkgs; [curl jq];
      ollama = [llm.ollama];
      hermes = [llm.hermes-agent pkgs.nodejs_22];
      default = common ++ api;
    in {inherit common api ollama hermes default;};

    log = "gum log --level";
    confirm = "gum confirm";

    mkProcess = pattern: let
      command = action: ''${action} -f -- ${
          escapeShellArg pattern
        } >/dev/null 2>&1'';
    in {
      check = command "pgrep";
      kill = command "pkill";
    };

    mkLaunch = name: runtime: command: let
      session = pkgs.writeShellApplication {
        name = "${name}-session";
        runtimeInputs = runtime;
        text = ''
          ${command}

          exec "''${SHELL:-${pkgs.runtimeShell}}"
        '';
      };
    in ''
      "$terminal" -e ${session}/bin/${name}-session \
        </dev/null >/dev/null 2>&1 &
    '';

    set-terminal = ''
      case "''${XDG_SESSION_TYPE:-}" in
        wayland) terminal="${pkgs.foot}/bin/foot" ;;
        *)
          case "''${DISPLAY:-}" in
            "")
              ${log} error "No display server detected."
              exit 1
            ;;
            *) terminal="${pkgs.xterm}/bin/xterm";;
          esac
        ;;
      esac
    '';

    mkWait = check: label: ''
      timeout="''${STARTUP_TIMEOUT:-15}"
      elapsed=0

      while [ "$elapsed" -lt "$timeout" ]; do
        if ${check}; then
          ${log} info "${label}"
          exit 0
        fi

        sleep 1
        elapsed=$((elapsed + 1))
      done

      ${log} warn "Timed out waiting for ${label}"
      exit 1
    '';

    mkArgs = args: concatMapStringsSep " " escapeShellArg args;

    mkAll = {
      name,
      action,
      passthru ? true,
    }: let
      args =
        if passthru
        then ''"$@"''
        else "";

      bins = map (service: commands.${service}.${action}) names;
    in
      mkBin name bins ''
        failed=0

        for service in ${concatStringsSep " " names}; do
          "$service-${action}" ${args} || failed=1
        done

        exit "$failed"
      '';

    mkService = name: cfg: let
      process = mkProcess cfg.process;
      check = cfg.check or process.check;
      kill = cfg.kill or process.kill;
      command = cfg.command or cfg.process;
      runtime = runtimes.default ++ (cfg.runtime or []);
      wait-label = cfg.wait.label or "${cfg.title} is running.";

      parseArguments = ''
        while [ "$#" -gt 0 ]; do
          case "$1" in
            -h|--help)
              echo "Usage: $0 [--yes|--force] [--no-wait]"
              exit 0;;
            -y|--yes|--no-confirm|--force) assume_yes=1;;
            --no-wait) wait=0;;
            *) printf "Unknown: %s" "$1"; exit 2;;
          esac
          shift
        done
      '';
    in {
      inherit check;
      start = let
        tag = "${name}-start";
      in
        mkBin tag runtime ''
          assume_yes=0
          wait=1

          while [ "$#" -gt 0 ]; do
            case "$1" in
              -y|--yes|--no-confirm) assume_yes=1 ;;
              --no-wait) wait=0 ;;
              -h|--help)
                gum style \
                  "${tag}" \
                  "  -y, --yes, --no-confirm   start without prompting" \
                  "  --no-wait                 do not wait for readiness"
                exit 0
              ;;
              *)
                ${log} error "Unknown option: $1"
                exit 2
              ;;
            esac

            shift
          done

          if ${check}; then
            ${log} warn "${cfg.title} already running - skipping."
            exit 0
          fi

          ${set-terminal}

          if [ "$assume_yes" -ne 1 ]; then
            ${confirm} "Start ${cfg.title}?" || exit 0
          fi

          ${mkLaunch name runtime command}

          ${log} info "${cfg.title} launched via $(basename "$terminal")."

          if [ "$wait" -eq 1 ]; then ${mkWait check wait-label}; fi
        '';

      stop = let
        tag = "${name}-stop";
      in
        mkBin tag runtime ''
          force=0

          while [ "$#" -gt 0 ]; do
            case "$1" in
              -f|--force|-y|--yes|--no-confirm) force=1 ;;
              -h|--help)
                gum style "${tag}" \
                  "  -f, --force               stop without prompting" \
                  "  -y, --yes, --no-confirm   stop without prompting"
                exit 0
              ;;
              *)
                ${log} error "Unknown option: $1"
                exit 2
              ;;
            esac

            shift
          done

          if ${check}; then
            :
          else
            ${log} warn "${cfg.title} is not running."
            exit 0
          fi

          if [ "$force" -ne 1 ]; then
            ${confirm} "Stop ${cfg.title}?" </dev/tty || {
              ${log} warn "${cfg.title} left active."
              exit 0
            }
          fi

          if ${kill}; then
            ${log} info "${cfg.title} stopped."
          else
            ${log} error "Failed to stop ${cfg.title}."
            exit 1
          fi
        '';

      status = mkBin "${name}-status" runtime ''
        if ${check}; then
          ${log} info "${cfg.title} is running."
        else
          ${log} warn "${cfg.title} is not running."
          exit 1
        fi
      '';

      help = mkBin "${name}-help" runtimes.common ''
        if ${check}; then
          gum style "${cfg.title}" ${mkArgs cfg.help.active}
        else
          gum style "${cfg.title}" ${mkArgs cfg.help.inactive}
        fi
      '';
    };

    services = {
      ollama = {
        title = "Ollama";
        process = "ollama serve";
        runtime = runtimes.ollama;

        check = ''
          curl -sf "$OLLAMA_LOCALHOST/api/tags" >/dev/null 2>&1
        '';

        wait = {
          label = "Ollama is reachable at $OLLAMA_LOCALHOST.";
        };

        help = {
          active = [
            "ollama-stop             stop Ollama"
            "ollama-status           check Ollama status"
            "ollama-models           list available models"
            "ollama-chat             chat with $OLLAMA_DEFAULT_MODEL"
            "ollama run <model>      chat with a specific model"
            "ollama pull <model>     download a model"
          ];

          inactive = [
            "ollama-start            start Ollama"
            "ollama-status           check Ollama status"
            "ollama run <model>      chat with a specific model"
            "ollama pull <model>     download a model"
          ];
        };
      };

      hermes = {
        title = "Hermes";
        process = "hermes gateway run";
        runtime = runtimes.hermes;

        wait = {
          label = "Hermes gateway is running.";
        };

        help = {
          active = [
            "hermes-stop             stop Hermes Gateway"
            "hermes-status           check Hermes Gateway status"
            "hermes chat             chat locally in the terminal"
          ];

          inactive = [
            "hermes-start            start Hermes Gateway"
            "hermes-status           check Hermes Gateway status"
            "hermes setup            setup Hermes if not already done"
            "hermes chat             chat locally in the terminal"
          ];
        };
      };
    };

    all = {
      start = mkAll {
        name = "start-services";
        action = "start";
      };

      stop = mkAll {
        name = "stop-services";
        action = "stop";
      };

      status = mkAll {
        name = "services-status";
        action = "status";
        passthru = false;
      };

      help = mkBin "help-services" [pkgs.gum] ''
        gum style "All Services" \
          "  start-services          start missing services" \
          "  stop-services           stop running services" \
          "  services-status         check all service statuses"
      '';
    };

    names = attrNames services;
    commands = mapAttrs mkService services;

    check-ollama-model = ''
      curl -sf "$OLLAMA_LOCALHOST/api/tags" \
        | jq -e --arg model "$OLLAMA_DEFAULT_MODEL" \
          'any(.models[]?; .name == $model)' \
        >/dev/null
    '';

    ollama-models = mkBin "ollama-models" runtimes.default ''
      if ollama-status >/dev/null 2>&1; then
        :
      else
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

    ollama-chat =
      mkBin "ollama-chat" (
        runtimes.default ++ runtimes.ollama
      ) ''
        if ollama-status >/dev/null 2>&1; then
          :
        else
          ${log} error "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"
          exit 1
        fi

        if ${check-ollama-model}; then
          :
        else
          ${log} error "Model '$OLLAMA_DEFAULT_MODEL' is not installed."
          ${log} info "Run: ollama pull $OLLAMA_DEFAULT_MODEL"
          exit 1
        fi

        ollama run "$OLLAMA_DEFAULT_MODEL"
      '';

    hermes-chat = mkBin "hermes-chat" runtimes.hermes ''
      hermes chat
    '';

    show-help = let
      mkSection = cmd: ''printf "%s\n\n" "$(${cmd})"'';
    in
      mkBin "show-help" (
        [pkgs.gum all.help]
        ++ map (name: commands.${name}.help) names
      ) ''
        gum style --border rounded --padding "0 1" --align left "$(
          gum style --bold --italic "${description}"

          ${concatStringsSep "\n" (
          map (name: mkSection "${name}-help") names
        )}
          ${mkSection "help-services"}
        )"
      '';
  in
    concatLists (map attrValues [commands all])
    ++ [
      ollama-models
      ollama-chat
      hermes-chat
      show-help
    ];

  shellHook = ''
    if [ -t 1 ]; then
      case "''${AUTO_START:-1}" in
        1) start-services --yes || true ;;
      esac

      show-help
    fi
  '';
in {inherit description env packages shellHook;}
