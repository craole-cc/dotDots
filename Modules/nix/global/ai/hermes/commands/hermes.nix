{
  helpers,
  runtimes,
  ...
}: let
  inherit (helpers)
    confirm
    env-file-functions
    log
    mkBin
    prepare-hermes-messaging
    prepare-whatsapp-bridge
    ;

  default-profile = import ../profiles/default.nix {
    inherit helpers runtimes;
  };

  dev-profile = import ../profiles/dev.nix {
    inherit helpers runtimes;
  };

  research-profile = import ../profiles/research.nix {
    inherit helpers runtimes;
  };

  writing-profile = import ../profiles/writing.nix {
    inherit helpers runtimes;
  };

  lab-profile = import ../profiles/lab.nix {
    inherit helpers runtimes;
  };
in
  default-profile
  // dev-profile
  // research-profile
  // writing-profile
  // lab-profile
  // {
    hermes-chat = mkBin "hermes-chat" runtimes.hermes ''
      ${log} warn "hermes-chat is deprecated; opening Hermes TUI instead"
      ${prepare-hermes-messaging}
      ${prepare-whatsapp-bridge}
      exec hermes "$@"
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
  }
