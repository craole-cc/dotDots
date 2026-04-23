#!/bin/sh
# shellcheck enable=all
set -eu

#~@ Injected by Nix via replaceVarsWith
CMD_SD="@cmdSd@"
CMD_DCONF="@cmdDconf@"
CMD_NOTIFY="@cmdNotify@"
CMD_WALLMAN="@cmdWallman@"
CFG_POLARITY="@cfgPolarity@"
CFG_API="@cfgApi@"
CFG_CAELESTIA_FLAVOUR="@cfgCaelestiaFlavour@"
CFG_VSCODE_THEME="@cfgVscodeTheme@"

#~@ State
STATE_FILE="${XDG_STATE_HOME:-${HOME:-}/.local/state}/theme-mode.state"

#~@ Skip if already in requested mode
if [ -f "${STATE_FILE}" ] && [ "$(cat "${STATE_FILE}")" = "${CFG_POLARITY}" ]; then
  printf 'Already in %s mode, skipping...\n' "${CFG_POLARITY}"
  exit 0
fi

printf '=== Switching to %s mode ===\n' "${CFG_POLARITY}"

#> Update polarity in user API config
printf 'Updating user API...\n'
"${CMD_SD}" 'polarity = "(dark|light)"' "polarity = \"${CFG_POLARITY}\"" "${CFG_API}" || {
  printf 'Warning: Failed to update API\n'
}

#> Set freedesktop portal via dconf (Hyprland-compatible)
#?  xdg-desktop-portal-hyprland does not support Settings.Write via dbus
#?  dconf directly writes to the same key without requiring GNOME schemas
printf 'Setting portal color-scheme...\n'
"${CMD_DCONF}" write /org/gnome/desktop/interface/color-scheme \
  "'prefer-${CFG_POLARITY}'" 2>/dev/null || {
  printf 'Warning: dconf write failed\n'
}

#> GTK theme (gsettings if available, dconf fallback)
#?  adw-gtk3 light variant has no suffix; dark variant is "adw-gtk3-dark"
printf 'Setting GTK theme...\n'
case "${CFG_POLARITY}" in
dark) gtk_theme="adw-gtk3-dark" ;;
light) gtk_theme="adw-gtk3" ;;
esac
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme \
    "prefer-${CFG_POLARITY}" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme \
    "${gtk_theme}" 2>/dev/null || true
else
  "${CMD_DCONF}" write /org/gnome/desktop/interface/gtk-theme \
    "'${gtk_theme}'" 2>/dev/null || true
fi

#> Update wallpapers
printf 'Updating wallpapers...\n'
"${CMD_WALLMAN}" set --polarity "${CFG_POLARITY}" 2>/dev/null || {
  printf 'Warning: Wallpaper update had issues\n'
}

#> Restart foot server with new theme
# printf 'Restarting foot server for %s theme...\n' "${CFG_POLARITY}"
# FOOT_PID=$(pgrep -x foot 2> /dev/null || printf "")
# if [ -n "${FOOT_PID}" ]; then
#   kill "${FOOT_PID}" 2> /dev/null || true
#   printf 'Foot server stopped, will restart with %s theme on next launch\n' "${CFG_POLARITY}"
# else
#   printf 'Warning: foot not running\n'
# fi

#> Sync caelestia scheme
printf 'Syncing caelestia scheme...\n'
if command -v caelestia >/dev/null 2>&1; then
  caelestia scheme set \
    -n catppuccin \
    -f "${CFG_CAELESTIA_FLAVOUR}" \
    -m "${CFG_POLARITY}" 2>/dev/null || {
    printf 'Warning: caelestia scheme change failed\n'
  }
else
  printf 'Warning: caelestia not in PATH\n'
fi

#> Sync VSCode theme
printf 'Syncing VSCode theme...\n'
VSCODE_SETTINGS="${HOME}/.config/Code/User/settings.json"
if [ -f "${VSCODE_SETTINGS}" ]; then
  "${CMD_SD}" \
    '"workbench.colorTheme": "[^"]*"' \
    '"workbench.colorTheme": "'"${CFG_VSCODE_THEME}"'"' \
    "${VSCODE_SETTINGS}" || true
else
  printf 'Warning: VSCode settings not found\n'
fi

#> Notify user
printf 'Notifying...\n'
"${CMD_NOTIFY}" \
  --urgency=low \
  --expire-time=2000 \
  "Theme" "Switched to ${CFG_POLARITY} mode" 2>/dev/null || true

#> Update state file
mkdir -p "$(dirname "${STATE_FILE}")"
printf '%s\n' "${CFG_POLARITY}" >"$STATE_FILE"

printf '=== Done ===\n'
