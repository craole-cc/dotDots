#!/bin/sh
#shellcheck enable=all
set -eu

cat << 'UNIT'
[Unit]
Description=Hermes Agent Gateway - Messaging Platform Integration
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=@gateway_exe@
WorkingDirectory=%h/.hermes
Environment=HERMES_HOME=%h/.hermes
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
