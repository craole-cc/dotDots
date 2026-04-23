#!/bin/sh
# Time-based + manual theme toggle

toggle_manual() {
  CURRENT=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "''")
  if [ "$CURRENT" = "'prefer-dark'" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    notify-send -u low "🌞 Light mode"
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    notify-send -u low "🌙 Dark mode"
  fi
}

auto_time() {
  HOUR=$(date +%H)
  if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  fi
}

case "$1" in
--toggle | -t) toggle_manual ;;
--auto | -a) auto_time ;;
*) toggle_manual ;; # Default manual
esac
