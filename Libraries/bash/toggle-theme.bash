#!/usr/bin/env bash
# universal-polarity-switch.sh

set -euo pipefail

# Default to toggle if no argument
MODE="${1:-toggle}"

# Get current polarity
CURRENT_POLARITY="${_POLARITY:-light}"
if [[ "$MODE" == "toggle" ]]; then
	if [[ "$CURRENT_POLARITY" == "light" ]]; then
		MODE="dark"
	else
		MODE="light"
	fi
fi

printf "Switching to %s mode...\n" "$MODE"

# 1. Update environment variable (system-wide)
export _POLARITY="$MODE"
printf "_POLARITY=%s" "$MODE" | sudo tee /etc/environment.d/polarity.conf >/dev/null

# 2. Update GSettings (if it works on your system)
if command -v gsettings &>/dev/null; then
	if [[ "$MODE" == "dark" ]]; then
		gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
		gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin Frappé'
	else
		gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
		gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin Latte'
	fi
fi

# 3. Update wallpapers using your wallman
if command -v wallman &>/dev/null; then
	wallman "$MODE"
fi

# 4. Update cursor theme
if [[ "$MODE" == "dark" ]]; then
	gsettings set org.gnome.desktop.interface cursor-theme 'material_dark_cursors'
else
	gsettings set org.gnome.desktop.interface cursor-theme 'material_light_cursors'
fi

# 5. Update icon theme
if [[ "$MODE" == "dark" ]]; then
	gsettings set org.gnome.desktop.interface icon-theme 'candy-icons-dark'
else
	gsettings set org.gnome.desktop.interface icon-theme 'candy-icons-light'
fi

# 6. Create a script to refresh all apps
cat >/tmp/refresh-theme.sh <<'EOF'
#!/bin/bash
# Refresh theme for various applications

# Signal applications to reload theme
killall -USR1 kitty 2>/dev/null || true
killall -USR1 foot 2>/dev/null || true

# For Wayland/Hyprland, you might need to restart some services
if command -v hyprctl &> /dev/null; then
    hyprctl reload
fi
EOF
chmod +x /tmp/refresh-theme.sh

printf "✅ Switched to %s mode!" "$MODE"
printf "Some applications may need to be restarted to see changes."
