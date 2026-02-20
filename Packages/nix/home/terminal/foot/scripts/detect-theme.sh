#!/usr/bin/env sh
#~@ Universal System Theme Detector
#? Detects system color scheme from multiple sources
#? Returns: "dark" or "light"

#> Helper to check if command exists
has_cmd() { command -v "$1" > /dev/null 2>&1; }

#| 1. Check KDE Plasma (most reliable for KDE)
if [ -f "$HOME/.config/kdeglobals" ]; then
  KDE_SCHEME=$(grep "^ColorScheme=" "$HOME/.config/kdeglobals" | head -1 | cut -d= -f2)
  case "$KDE_SCHEME" in
    *[Dd]ark*)
      echo "dark"
      exit 0
      ;;
    *[Ll]ight*)
      echo "light"
      exit 0
      ;;
    # If no Dark/Light in name, check the hash or other indicators
    *)
      # Check if there's a "Color=" line in the Inactive section (dark themes have darker colors)
      INACTIVE_COLOR=$(grep -A5 "^\[ColorEffects:Inactive\]" "$HOME/.config/kdeglobals" | grep "^Color=" | cut -d= -f2)
      if [ -n "$INACTIVE_COLOR" ]; then
        # Parse RGB values (format: R,G,B)
        R=$(echo "$INACTIVE_COLOR" | cut -d, -f1)
        # If red component is > 100, likely light theme
        if [ "$R" -gt 100 ] 2> /dev/null; then
          echo "light"
          exit 0
        else
          echo "dark"
          exit 0
        fi
      fi
      ;;
  esac
fi

#| 2. Check freedesktop portal (works with some DEs)
if has_cmd dbus-send; then
  THEME=$(dbus-send --session --print-reply=literal --reply-timeout=100 \
    --dest=org.freedesktop.portal.Desktop \
    /org/freedesktop/portal/desktop \
    org.freedesktop.portal.Settings.Read \
    string:'org.freedesktop.appearance' string:'color-scheme' 2> /dev/null \
    | grep -oE 'uint32 [0-9]+' | awk '{print $2}')

  case "$THEME" in
    1)
      echo "dark"
      exit 0
      ;;
    2)
      echo "light"
      exit 0
      ;;
  esac
fi

#| 3. Check GNOME settings
if has_cmd gsettings; then
  SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2> /dev/null || echo "")
  case "$SCHEME" in
    *dark* | *prefer-dark*)
      echo "dark"
      exit 0
      ;;
    *light* | *prefer-light*)
      echo "light"
      exit 0
      ;;
  esac
fi

#| 4. Check GTK theme
for conf in "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"; do
  if [ -f "$conf" ]; then
    GTK_THEME=$(grep "^gtk-theme-name" "$conf" | cut -d= -f2 | tr -d ' "')
    case "$GTK_THEME" in
      *[Dd]ark*)
        echo "dark"
        exit 0
        ;;
      *[Ll]ight*)
        echo "light"
        exit 0
        ;;
    esac
  fi
done

#| 5. Check environment variables
case "${GTK_THEME:-}:${QT_STYLE_OVERRIDE:-}" in
  *[Dd]ark*)
    echo "dark"
    exit 0
    ;;
  *[Ll]ight*)
    echo "light"
    exit 0
    ;;
esac

#| 6. Time-based fallback (6am-6pm = light, otherwise dark)
HOUR=$(date +%H)
if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
  echo "light"
else
  echo "dark"
fi
