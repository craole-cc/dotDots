#!/bin/sh
set -eu

cat <<EOF
Hermes shell

  hermes              Agent CLI
  hermes-desktop      Official desktop
  hermes-one          Community desktop
  hermes-hud          Status TUI
  hermes-tui          Official TUI
  hermes-whatsapp     Pair/configure WhatsApp bridge

  start [--no-confirm]
  show-help

  HERMES_HOME=${HERMES_HOME:-unset}
EOF
