#!/bin/sh
#shellcheck enable=all
set -eu

: "${HERMES_HOME:?HERMES_HOME not set}"
: "${HERMES_GATEWAY_CFG:?HERMES_GATEWAY_CFG not set}"

gateway_exe='@gateway_exe@'

cat << UNIT
[Unit]
Description=Hermes Agent Gateway - Messaging Platform Integration
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${gateway_exe}
WorkingDirectory=${HERMES_HOME}
Environment=HERMES_HOME=${HERMES_HOME}
Environment=HERMES_GATEWAY_CFG=${HERMES_GATEWAY_CFG}
Restart=always
RestartSec=5
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
UNIT
