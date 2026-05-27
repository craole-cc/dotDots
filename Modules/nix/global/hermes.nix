{dots, ...}: let
  inherit (dots) pkgs lib inputPkgs pythonPkgs;
  inherit (lib.attrsets) attrNames attrValues isAttrs mapAttrs;
  inherit (lib.lists) concatLists;
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

    AUTO_START = 0;
    STARTUP_TIMEOUT = 15;
  };

  #|---------------------------------------------------------|
  #| Packages -----------------------------------------------|
  #|---------------------------------------------------------|
  apps = {
    common = {inherit (pkgs) coreutils gum procps curl jq;};
    api = {inherit (pkgs) curl jq;};
    hermes = {
      agent = (inputPkgs "hermes-agent").default;
      telegram = pythonPkgs.withPackages (pkg: [pkg.python-telegram-bot]);
      inherit (pkgs) openai nodejs_22 jq;
    };
    ollama = {inherit (pkgs) ollama;};
  };
  paths = {
    hermes = apps.hermes.agent.outPath;
    telegram = "${apps.hermes.telegram}/lib/python3.12/site-packages";
  };
  runtimes = let
    common = attrValues apps.common;
    api = attrValues apps.api;
    ollama = attrValues apps.ollama;
    hermes = attrValues apps.hermes;
    default = common;
    all = default ++ ollama ++ hermes;
  in {
    inherit common api ollama hermes default all;
  };
  # runtimes = let
  #   common = attrNames apps.common;
  #   api = attrNames apps.api;
  #   ollama = attrNames apps.ollama;
  #   hermes = attrNames apps.hermes;
  #   # common = with pkgs; [coreutils gum procps];
  #   # api = with pkgs; [curl jq];
  #   # ollama = [pkgs.ollama];
  #   # hermes =
  #   #   (attrNames apps.core)
  #   #   ++ (with pkgs; [openai nodejs_22 jq]);
  #   default = common;
  #   all = default ++ ollama ++ hermes;
  # in {inherit common api ollama hermes default all;};

  packages = let
    #|---------------------------------------------------------|
    #| Utilities ----------------------------------------------|
    #|---------------------------------------------------------|
    mkBin = name: runtimeInputs: text:
      pkgs.writeShellApplication {
        inherit name runtimeInputs text;
      };

    log = "gum log --level";
    confirm = "gum confirm";

    prepare-hermes-messaging = ''
      export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
      export PYTHONPATH="${paths.telegram}''${PYTHONPATH:+:$PYTHONPATH}"
    '';

    prepare-whatsapp-bridge = ''
            bridge_src=${escapeShellArg "${paths.hermes}/scripts/whatsapp-bridge"}
            bridge_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"
            bridge_script="$bridge_dir/bridge.js"
            gateway_json="$HERMES_HOME/gateway.json"

            mkdir -p "$bridge_dir" "$HERMES_HOME"

            cp -f \
              "$bridge_src/allowlist.js" \
              "$bridge_src/allowlist.test.mjs" \
              "$bridge_src/bridge.js" \
              "$bridge_src/package.json" \
              "$bridge_src/package-lock.json" \
              "$bridge_dir/"

            if [ ! -d "$bridge_dir/node_modules" ] \
              || [ "$bridge_src/package-lock.json" -nt "$bridge_dir/node_modules" ]
            then
              ${log} info "Installing WhatsApp bridge dependencies in $bridge_dir"
              (
                cd "$bridge_dir" || exit 1
                npm ci --no-fund --no-audit --progress=false >/dev/null
              )
            fi

            python - "$gateway_json" "$bridge_script" <<'PY'
      import json
      import pathlib
      import sys

      gateway_path = pathlib.Path(sys.argv[1])
      bridge_script = sys.argv[2]

      if gateway_path.exists():
          try:
              data = json.loads(gateway_path.read_text())
          except Exception:
              data = {}
      else:
          data = {}

      platforms = data.setdefault("platforms", {})
      whatsapp = platforms.setdefault("whatsapp", {})
      extra = whatsapp.setdefault("extra", {})
      extra["bridge_script"] = bridge_script

      gateway_path.write_text(json.dumps(data, indent=2) + "\n")
      PY
    '';

    env-file-functions = ''
            env_file="$HERMES_HOME/.env"
            mkdir -p "$HERMES_HOME"
            touch "$env_file"

            env_get() {
              key="$1"
              sed -n "s/^''${key}=//p" "$env_file" | tail -n 1
            }

            env_set() {
              key="$1"
              value="$2"
              python - "$env_file" "$key" "$value" <<'PY'
      import pathlib
      import sys

      env_path = pathlib.Path(sys.argv[1])
      key = sys.argv[2]
      value = sys.argv[3]

      lines = []
      if env_path.exists():
          lines = env_path.read_text().splitlines()

      prefix = f"{key}="
      updated = False
      for index, line in enumerate(lines):
          if line.startswith(prefix):
              lines[index] = f"{key}={value}"
              updated = True
              break

      if not updated:
          lines.append(f"{key}={value}")

      env_path.write_text("\n".join(lines) + "\n")
      PY
            }
    '';

    renderHelp = arg: let
      content =
        if isAttrs arg
        then arg.content or []
        else arg;
      faint =
        if isAttrs arg
        then arg.faint or false
        else false;
    in
      concatMapStringsSep "\n"
      (line:
        if faint
        then ''gum style --faint "  ${line}"''
        else ''gum style "  ${line}"'')
      content;

    #|---------------------------------------------------------|
    #| Terminal Detection -------------------------------------|
    #|---------------------------------------------------------|
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

    #|---------------------------------------------------------|
    #| Process Helpers ----------------------------------------|
    #|---------------------------------------------------------|
    mkProcess = pattern: let
      cmd = action: ''${action} -f -- ${escapeShellArg pattern} >/dev/null 2>&1'';
    in {
      check = cmd "pgrep";
      kill = cmd "pkill";
    };

    mkWait = check: label: ''
      timeout="''${STARTUP_TIMEOUT:-15}"
      elapsed=0

      _wait_check() {
        ${check}
      }

      while [ "$elapsed" -lt "$timeout" ]; do
        if _wait_check; then
          ${log} info "${label}"
          break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
      done

      if [ "$elapsed" -ge "$timeout" ]; then
        ${log} warn "Timed out waiting for ${label}"
        exit 1
      fi
    '';

    #|---------------------------------------------------------|
    #| Check Helpers ------------------------------------------|
    #|---------------------------------------------------------|
    mkCheck = {
      check,
      msg,
      level ? "error",
      action ? "exit 1",
      invert ? false,
    }: let
      condition =
        if invert
        then "_mkcheck"
        else "! _mkcheck";
    in ''
      _mkcheck() {
        ${check}
      }
      if ${condition}; then
        ${log} ${level} "${msg}"
        ${action}
      fi
    '';

    mkRequire = args:
      mkCheck ({
          level = "error";
          action = "exit 1";
          invert = false;
        }
        // args);

    #|---------------------------------------------------------|
    #| Argument Parsers ---------------------------------------|
    #|---------------------------------------------------------|
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

    #|---------------------------------------------------------|
    #| Launcher -----------------------------------------------|
    #|---------------------------------------------------------|
    mkLaunch = name: runtime: command: let
      session = pkgs.writeShellApplication {
        name = "${name}-session";
        runtimeInputs = runtime;
        text = command;
      };
    in ''
      "$terminal" -e ${session}/bin/${name}-session \
        </dev/null >/dev/null 2>&1 &
    '';

    #|---------------------------------------------------------|
    #| Services -----------------------------------------------|
    #|---------------------------------------------------------|
    mkService = name: cfg: let
      process = mkProcess cfg.process;
      check = cfg.check or process.check;
      kill = cfg.kill or process.kill;
      command = cfg.command or cfg.process;
      runtime = runtimes.default ++ (cfg.runtime or []);
      wait-label = cfg.wait.label or "${cfg.title} is running.";
    in {
      inherit check;

      start = mkBin "${name}-start" runtime ''
        assume_yes=0
        wait=1

        ${parseStartArgs}

        ${mkCheck {
          inherit check;
          msg = "${cfg.title} already running - skipping.";
          level = "warn";
          action = "exit 0";
          invert = true;
        }}

        ${set-terminal}
        clear

        if [ "$assume_yes" -ne 1 ]; then
          ${confirm} "Start ${cfg.title}?" || exit 0
        fi

        ${mkLaunch name runtime command}

        ${log} info "${cfg.title} launched via $(basename "$terminal")."

        if [ "$wait" -eq 1 ]; then
          ${mkWait check wait-label}
        fi

        show-help
      '';

      stop = mkBin "${name}-stop" runtime ''
        force=0
        clear

        ${parseStopArgs}

        ${mkCheck {
          inherit check;
          msg = "${cfg.title} is not running.";
          level = "warn";
          action = "exit 0";
        }}

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

        show-help
      '';

      status = mkBin "${name}-status" runtime ''
        ${mkCheck {
          inherit check;
          msg = "${cfg.title} is not running.";
          level = "warn";
          action = "exit 1";
        }}

        ${log} info "${cfg.title} is running."
      '';

      help = mkBin "${name}-help" runtimes.common ''
        _help_check() {
          ${check}
        }

        gum style "${cfg.title}"

        if _help_check; then
          ${renderHelp cfg.help.running}
          ${renderHelp cfg.help.common}
          ${renderHelp {
          content = cfg.help.stopped;
          faint = true;
        }}
        else
          ${renderHelp cfg.help.stopped}
          ${renderHelp cfg.help.common}
          ${renderHelp {
          content = cfg.help.running;
          faint = true;
        }}
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
    };
    names = attrNames services;
    commands = mapAttrs mkService services;

    #|---------------------------------------------------------|
    #| Aggregate Commands -------------------------------------|
    #|---------------------------------------------------------|
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

    all = {
      start = mkAll {
        name = "start";
        action = "start";
      };
      stop = mkAll {
        name = "stop";
        action = "stop";
      };
      status = mkAll {
        name = "status";
        action = "status";
        passthru = false;
      };

      help = mkBin "help-services" [pkgs.gum] ''
        gum style "All Services" \
          "  status                  Check all service statuses" \
          "  start                   Start missing services" \
          "  stop                    Stop running services"
      '';
    };

    #|---------------------------------------------------------|
    #| Ollama-specific Commands -------------------------------|
    #|---------------------------------------------------------|
    check-ollama-model = ''
      curl -sf "$OLLAMA_LOCALHOST/api/tags" \
        | jq -e --arg model "$OLLAMA_DEFAULT_MODEL" \
          'any(.models[]?; .name == $model)' \
        >/dev/null
    '';

    ollama-models = mkBin "ollama-models" runtimes.default ''
      ${mkRequire {
        check = "ollama-status >/dev/null 2>&1";
        msg = "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?";
      }}

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
      ${mkRequire {
        check = "ollama-status >/dev/null 2>&1";
        msg = "Ollama not reachable at $OLLAMA_LOCALHOST - is it running?";
      }}

      ${mkRequire {
        check = check-ollama-model;
        msg = "Model '$OLLAMA_DEFAULT_MODEL' is not installed.";
        action = ''
          ${log} info "Run: ollama pull $OLLAMA_DEFAULT_MODEL"
          exit 1
        '';
      }}

      ollama run "$OLLAMA_DEFAULT_MODEL"
    '';

    #|---------------------------------------------------------|
    #| Hermes-specific Commands -------------------------------|
    #|---------------------------------------------------------|
    hermes-tui = mkBin "hermes-tui" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes "$@"
    '';
    hermes-chat = mkBin "hermes-chat" runtimes.hermes ''
      ${log} warn "hermes-chat is deprecated; opening Hermes TUI instead"
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes "$@"
    '';
    hermes-dev = mkBin "hermes-dev" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile dev "$@"
    '';
    hermes-research = mkBin "hermes-research" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile research "$@"
    '';
    hermes-writing = mkBin "hermes-writing" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile writing "$@"
    '';
    hermes-lab = mkBin "hermes-lab" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile lab "$@"
    '';
    hermes-setup = mkBin "hermes-setup" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      hermes setup
    '';
    hermes-whatsapp = mkBin "hermes-whatsapp" runtimes.hermes ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      ${env-file-functions}

      mode="$(env_get WHATSAPP_MODE)"
      allowed_users="$(env_get WHATSAPP_ALLOWED_USERS)"
      session_dir="$HERMES_HOME/whatsapp/session"
      bridge_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"

      mkdir -p "$session_dir"

      if [ -z "$mode" ]; then
        ${log} info "Choose how Hermes should use WhatsApp"
        choice="$(printf 'bot\nself-chat\n' | gum choose --header 'WhatsApp mode')"
        case "$choice" in
          bot|self-chat) mode="$choice" ;;
          *)
            ${log} error "WhatsApp setup cancelled"
            exit 1
          ;;
        esac
        env_set WHATSAPP_MODE "$mode"
      fi

      if [ -z "$allowed_users" ]; then
        case "$mode" in
          bot)
            prompt='Allowed phone numbers (comma-separated, country code, no +; use * for anyone)'
          ;;
          *)
            prompt='Your phone number (country code, no +)'
          ;;
        esac

        allowed_users="$(gum input --prompt "$prompt: ")"
        if [ -z "$allowed_users" ]; then
          ${log} error "WhatsApp allowlist cannot be empty"
          exit 1
        fi
        env_set WHATSAPP_ALLOWED_USERS "$allowed_users"
      fi

      if [ -f "$session_dir/creds.json" ]; then
        if ${confirm} 'Existing WhatsApp session found. Re-pair now?'; then
          rm -rf "$session_dir"
          mkdir -p "$session_dir"
        else
          env_set WHATSAPP_ENABLED true
          ${log} info "WhatsApp remains paired and enabled."
          exit 0
        fi
      fi

      (cd "$bridge_dir" && node ./bridge.js --pair-only --session "$session_dir")

      if [ -f "$session_dir/creds.json" ]; then
        env_set WHATSAPP_ENABLED true
        ${log} info "WhatsApp paired successfully. Start Hermes with: hermes-start"
      else
        ${log} error "WhatsApp pairing did not complete. Re-run hermes-whatsapp."
        exit 1
      fi
    '';

    #|---------------------------------------------------------|
    #| Help Commands ------------------------------------------|
    #|---------------------------------------------------------|
    show-help = let
      mkSection = cmd: ''printf "%s\n\n" "$(${cmd})"'';
      hr = ''gum style --faint "──────────────────────────────────────────────────────"'';
    in
      mkBin "show-help" (
        [pkgs.gum all.help]
        ++ map (name: commands.${name}.help) names
      ) ''
        gum style --border rounded --padding "0 1" --align left "$(
          gum style --bold --italic "${description}"
          ${hr}

          ${mkSection "help-services"}

          ${concatStringsSep "\n" (
          map (name: mkSection "${name}-help") names
        )}
        )"
      '';
  in
    concatLists [
      (concatLists (map (svc:
        with svc; [
          start
          stop
          status
          help
        ]) (attrValues commands)))
      (attrValues all)
    ]
    ++ [
      ollama-models
      ollama-chat
      hermes-tui
      hermes-chat
      hermes-dev
      hermes-research
      hermes-writing
      hermes-lab
      hermes-setup
      hermes-whatsapp
      show-help
    ];

  shellHook = ''
    if [ -t 1 ]; then
      case "''${AUTO_START:-1}" in
        1) start --no-confirm || true ;;
        *) start || true ;;
      esac
      show-help
    fi
  '';
in {
  inherit description env shellHook;
  packages = packages ++ runtimes.all;
}
