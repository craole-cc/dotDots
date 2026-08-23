#!/bin/sh
#shellcheck enable=all
set -eu

if [ -n "${HERMES_ENV_SH:-}" ] && [ -f "$HERMES_ENV_SH" ]; then
  # shellcheck disable=SC1090
  . "$HERMES_ENV_SH"
fi

: "${HERMES_HOME:?HERMES_HOME not set}"
: "${HERMES_WHATSAPP_BRIDGE_DIR:?HERMES_WHATSAPP_BRIDGE_DIR not set}"

session_dir="$HERMES_HOME/whatsapp/session"
mkdir -p "$session_dir"

mode="$(env_get WHATSAPP_MODE)"
allowed_users="$(env_get WHATSAPP_ALLOWED_USERS)"

if [ -z "$mode" ]; then
  gum log --level info "Choose how Hermes should use WhatsApp"
  choice="$(printf 'bot\nself-chat\n' | gum choose --header 'WhatsApp mode')"
  case "$choice" in
    bot | self-chat) mode="$choice" ;;
    *)
      gum log --level error "WhatsApp setup cancelled"
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
    gum log --level error "WhatsApp allowlist cannot be empty"
    exit 1
  fi
  env_set WHATSAPP_ALLOWED_USERS "$allowed_users"
fi

if [ -f "$session_dir/creds.json" ]; then
  if gum confirm 'Existing WhatsApp session found. Re-pair now?'; then
    rm -rf "$session_dir"
    mkdir -p "$session_dir"
  else
    env_set WHATSAPP_ENABLED true
    gum log --level info "WhatsApp remains paired and enabled."
    exit 0
  fi
fi

(cd "$HERMES_WHATSAPP_BRIDGE_DIR" && node ./bridge.js --pair-only --session "$session_dir")

if [ -f "$session_dir/creds.json" ]; then
  env_set WHATSAPP_ENABLED true
  gum log --level info "WhatsApp paired successfully. Start Hermes with: start"
else
  gum log --level error "WhatsApp pairing did not complete. Re-run hermes-whatsapp."
  exit 1
fi
