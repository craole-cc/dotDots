#!/bin/sh
#shellcheck enable=all
set -eu

: "${ADGUARD_BIND_ADDRESS:?ADGUARD_BIND_ADDRESS not set}"
: "${ADGUARD_DNS_PORT:?ADGUARD_DNS_PORT not set}"
: "${ADGUARD_WEB_PORT:?ADGUARD_WEB_PORT not set}"
: "${ADGUARD_DATA_DIR:?ADGUARD_DATA_DIR not set}"
: "${ADGUARD_CONFIG_FILE:?ADGUARD_CONFIG_FILE not set}"
: "${ADGUARD_SYSTEMD_UNIT:?ADGUARD_SYSTEMD_UNIT not set}"

# Ensure we have the Nix-built binary
BINARY="$(command -v AdGuardHome || true)"
if [ -z "${BINARY}" ] || [ ! -x "${BINARY}" ]; then
  echo "AdGuardHome binary not found in PATH" >&2
  exit 1
fi

# Install wrapper to /usr/local/bin so systemd can find it
sudo -n install -m 755 "${BINARY}" /usr/local/bin/adguardhome-nix

# Create the systemd directory
sudo -n mkdir -p /var/lib/adguardhome
sudo -n chown root:root /var/lib/adguardhome

# Install the unit
sudo -n install -m 644 "${ADGUARD_SYSTEMD_UNIT}" /etc/systemd/system/adguardhome.service

# Reload systemd and enable
sudo -n systemctl daemon-reload
sudo -n systemctl enable --now adguardhome.service

echo "Service installed and started. Check with: sudo systemctl status adguardhome.service"