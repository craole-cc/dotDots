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
    # -- Utilities -----------------------------------------------------------

    mkBin = name: runtimeInputs: text:
      pkgs.writeShellApplication {
        inherit name runtimeInputs text;
      };

    log = "gum log --level";
    confirm = "gum confirm";

    mkArgs = args: concatMapStringsSep " " escapeShellArg args;

    require = check: msg: ''
      if ! ${check} >/dev/null 2>&1; then
        ${log} error "${msg}"
        exit 1
      fi
    '';

    # -- Runtime collections -------------------------------------------------

    runtimes = let
      common = with pkgs; [coreutils gum procps];
      api = with pkgs; [curl jq];
      ollama = [llm.ollama];
      hermes = [llm.hermes-agent pkgs.nodejs_22];
      default = common ++ api;
    in {inherit common api ollama hermes default;};

    # -- Terminal detection --------------------------------------------------

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

    # -- Process helpers -----------------------------------------------------

    mkProcess = pattern: let
      cmd = action: ''${action} -f -- ${escapeShellArg pattern} >/dev/null 2>&1'';
    in {
      check = cmd "pgrep";
      kill  = cmd "pkill";
    };

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

    # -- Argument parsers ----------------------------------------------------

    parseStartArgs = ''
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -y|--yes|--no-confirm) assume_yes=1 ;;
          --no-wait)             wait=0 ;;
          -h|--help)
            gum style \
              "  -y, --yes, --no-confirm   start without prompting" \
              "  --no-wait                 do not wait for readiness"
            exit 0;;
          *)
            ${log} error "Unknown option: $1"
            exit 2;;
        esac
        shift
      done
    '';

    parseStopArgs = ''
      while [ "$#" -gt 0 ]; do
        case "$1" in
          -f|--force|-y|--yes|--no-confirm) force=1 ;;
          -h|--help)
            gum style \
              "  -f, --force               stop without prompting" \
              "  -y, --yes, --no-confirm   stop without prompting"
            exit 0;;
          *)
            ${log} error "Unknown option: $1"
            exit 2;;
        esac
        shift
      done
    '';

    # -- Launch helper -------------------------------------------------------

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

    # -- Service definitions -------------------------------------------------

    services = {
      ollama = {
        title = "Ollama";
        process = "ollama serve";
        runtime = runtimes.ollama;

        check = ''
          curl -sf "$OLLAMA_LOCALHOST/api/tags" >/dev/null 2>&1
        '';

        wait.label = "Ollama is reachable at $OLLAMA_LOCALHOST.";

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

        wait.label = "Hermes gateway is running.";

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

    names = attrNames services;

    # -- Per-service command generators --------------------------------------

    mkService = name: cfg: let
      process = mkProcess cfg.process;
      check   = cfg.check or process.check;
      kill    = cfg.kill or process.kill;
      command = cfg.command or cfg.process;
      runtime = runtimes.default ++ (cfg.runtime or []);
      wait-label = cfg.wait.label or "${cfg.title} is running.";
    in {
      inherit check;

      start = mkBin "${name}-start" runtime ''
        assume_yes=0
        wait=1

        ${parseStartArgs}

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

        if [ "$wait" -eq 1 ]; then
          ${mkWait check wait-label}
        fi
      '';

      stop = mkBin "${name}-stop" runtime ''
        force=0

        ${parseStopArgs}

        if ! ${check}; then
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

    commands = mapAttrs mkService services;

    # -- Aggregate commands --------------------------------------------------

    mkAll = {
      name,
      action,
      passthru ? true,
    }: let
      args = if passthru then ''"$@"'' else "";
      bins = map (service: commands.${service}.${action}) names;
    in
      mkBin name bins ''
        failed=0
        for service in ${concatStringsSep " " names}; do
          "$service-${action}" ${args} || failed=1
        done
        exit "$failed"
      '';

    all = {
      start  = mkAll { name = "start-services";  action = "start"; };
      stop   = mkAll { name = "stop-services";   action = "stop"; };
      status = mkAll { name = "services-status"; action = "status"; passthru = false; };

      help = mkBin "help-services" [pkgs.gum] ''
        gum style "All Services" \
          "  start-services          start missing services" \
          "  stop-services           stop running services" \
          "  services-status         check all service statuses"
      '';
    };

    # -- Ollama-specific commands --------------------------------------------

    check-ollama-model = ''
      curl -sf "$OLLAMA_LOCALHOST/api/tags" \
        | jq -e --arg model "$OLLAMA_DEFAULT_MODEL" \
          'any(.models[]?; .name == $model)' \
        >/dev/null
    '';

    ollama-models = mkBin "ollama-models" runtimes.default ''
      ${require "ollama-status" "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"}

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

    ollama-chat = mkBin "ollama-chat" (runtimes.default ++ runtimes.ollama) ''
      ${require "ollama-status" "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?"}

      if ! ${check-ollama-model}; then
        ${log} error "Model '$OLLAMA_DEFAULT_MODEL' is not installed."
        ${log} info "Run: ollama pull $OLLAMA_DEFAULT_MODEL"
        exit 1
      fi

      ollama run "$OLLAMA_DEFAULT_MODEL"
    '';

    # -- Hermes-specific commands --------------------------------------------

    hermes-chat = mkBin "hermes-chat" runtimes.hermes ''
      hermes chat
    '';

    # -- Help display --------------------------------------------------------

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
