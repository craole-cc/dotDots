{
  env,
  cmds,
  ...
}: let
  inherit (cmds) helpers runtimes service-builder;
  inherit (helpers) confirm log mkBin pkgs;
  inherit (service-builder) mkRequire;
  inherit (pkgs.lib.strings) escapeShellArg;
  inherit (pkgs.lib.trivial) readFile;

  agent =
    (env.pkgsFor {
      sources = {
        hermes-agent = "llm-agents";
      };
    }).packages;

  hermesPkg = builtins.head agent;
  hermesPath = hermesPkg.outPath or "";

  telegram = pkgs.pythonPkgs.withPackages (pkg: [pkg.python-telegram-bot]);
  telegramPath = "${telegram}/lib/python3.12/site-packages";

  prepare-hermes-messaging = ''
    export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
    export PYTHONPATH="${telegramPath}''${PYTHONPATH:+:$PYTHONPATH}"
  '';

  prepare-whatsapp-bridge = ''
    export HERMES_WHATSAPP_BRIDGE_SRC=${escapeShellArg "${hermesPath}/scripts/whatsapp-bridge"}
    export HERMES_WHATSAPP_BRIDGE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"
    export HERMES_WHATSAPP_GATEWAY_PY=${escapeShellArg "${./gateways/whatsapp/gateway.py}"}
    ${readFile ./gateways/whatsapp/bridge.sh}
  '';

  env-file-functions = ''
    export HERMES_ENV_PY=${escapeShellArg "${../../common/environment/env.py}"}
    ${readFile ../../common/environment/env.sh}
  '';

  profiles = {
    hermes-tui = mkBin "hermes-tui" agent ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes "$@"
    '';

    hermes-dev = mkBin "hermes-dev" agent ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile dev "$@"
    '';

    hermes-research = mkBin "hermes-research" agent ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile research "$@"
    '';

    hermes-writing = mkBin "hermes-writing" agent ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile writing "$@"
    '';

    hermes-lab = mkBin "hermes-lab" agent ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes --profile lab "$@"
    '';
  };

  hermes-chat = mkBin "hermes-chat" agent ''
    ${log} warn "hermes-chat is deprecated; opening Hermes TUI instead"
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    exec hermes "$@"
  '';

  hermes-setup = mkBin "hermes-setup" agent ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    hermes setup
  '';

  hermes-whatsapp = mkBin "hermes-whatsapp" agent ''
    ${prepare-hermes-messaging}
    ${prepare-whatsapp-bridge}
    ${env-file-functions}

    mode="$(env_get WHATSAPP_MODE)"
    allowed_users="$(env_get WHATSAPP_ALLOWED_USERS)"
    session_dir="$HERMES_HOME/whatsapp/session"
    bridge_dir="''${HERMES_WHATSAPP_BRIDGE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge}"

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

  service = {
    title = "Hermes";
    process = "hermes.*gateway";
    command = ''
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes gateway run
    '';
    runtime = agent;

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
in {
  env = {};

  packages = agent ++ [telegram];

  commands = {
    inherit service;
    extra =
      profiles
      // {
        inherit hermes-chat hermes-setup hermes-whatsapp;
      };
  };
}
