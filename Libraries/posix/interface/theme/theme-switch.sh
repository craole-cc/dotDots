#!/bin/sh
# shellcheck enable=all
#
# theme-switch - switch light/dark mode everywhere at once.
#
# Every backend is used only if its tool is installed (and, where noted, the
# session matches), so one script works across DMS, Plasma, GNOME, XFCE, ...
#
#   DankMaterialShell  dms ipc call theme light|dark
#   KDE Plasma 6       plasma-apply-colorscheme / plasma-apply-lookandfeel
#   GTK, libadwaita, xdg-desktop-portal
#                      gsettings (org.gnome.desktop.interface)
#   XFCE               xfconf-query (only in an XFCE session)
#   Your own tweaks    executables in ~/.config/theme-switch/hooks.d/,
#                      each called as: hook light|dark
#
# Optional environment overrides (all have sane defaults):
#   THEME_LIGHT_START / THEME_DARK_START   hours for --auto (default 6 / 18)
#   THEME_KDE_SCHEME_LIGHT / _DARK         default BreezeLight / BreezeDark
#   THEME_KDE_LOOKANDFEEL_LIGHT / _DARK    e.g. org.kde.breeze.desktop; when set,
#                                          used instead of the color scheme
#   THEME_GTK_LIGHT / _DARK                GTK theme name (gsettings)
#   THEME_ICONS_LIGHT / _DARK              icon theme name (gsettings)
#   THEME_XFCE_LIGHT / _DARK               default Greybird / Greybird-dark

THEME_LIGHT_START="${THEME_LIGHT_START:-6}"
THEME_DARK_START="${THEME_DARK_START:-18}"

state_dir="${XDG_STATE_HOME:-${HOME:-}/.local/state}/theme-switch"
state_file="${state_dir}/mode"
hook_dir="${XDG_CONFIG_HOME:-${HOME:-}/.config}/theme-switch/hooks.d"

# ---------------------------------------------------------------- helpers ---

have() {
  command -v "${1}" > /dev/null 2>&1
}

# True if XDG_CURRENT_DESKTOP (a colon-separated list) contains "${1}".
session_is() {
  case ":${XDG_CURRENT_DESKTOP:-}:" in
    *":${1}:"*) return 0 ;;
    *) return 1 ;;
  esac
}

notify() {
  if have notify-send; then
    notify-send -a theme-switch -u low "${1}" > /dev/null 2>&1
  elif have gdbus; then
    gdbus call --session --dest org.freedesktop.Notifications \
      --object-path /org/freedesktop/Notifications \
      --method org.freedesktop.Notifications.Notify \
      theme-switch 0 '' "${1}" '' '[]' '{}' 3000 > /dev/null 2>&1
  elif have busctl; then
    busctl --user call org.freedesktop.Notifications \
      /org/freedesktop/Notifications org.freedesktop.Notifications Notify \
      'susssasa{sv}i' theme-switch 0 '' "${1}" '' 0 0 3000 > /dev/null 2>&1
  elif have kdialog; then
    kdialog --passivepopup "${1}" 3 > /dev/null 2>&1
  fi
  return 0
}

announce() {
  if [ "${1}" = light ]; then
    notify '🌞 Light mode'
  else
    notify '🌙 Dark mode'
  fi
}

# ------------------------------------------------- detect the current mode ---
# Each query_* sets "current" to light or dark, or leaves it untouched when the
# tool is missing or gives no usable answer.

query_dms() {
  have dms || return 0
  value=$(dms ipc call theme getMode 2> /dev/null)
  case "${value}" in
    *[Dd]ark*) current=dark ;;
    *[Ll]ight*) current=light ;;
    *) ;;
  esac
}

query_gsettings() {
  have gsettings || return 0
  value=$(gsettings get org.gnome.desktop.interface color-scheme 2> /dev/null)
  case "${value}" in
    "'prefer-dark'") current=dark ;;
    "'prefer-light'") current=light ;;
    *) ;;
  esac
}

query_kde() {
  have kreadconfig6 || return 0

  # Judge by the window background brightness so custom schemes (whatever
  # they are called) are detected correctly.
  rgb=$(kreadconfig6 --file kdeglobals --group 'Colors:Window' --key BackgroundNormal 2> /dev/null)
  red=${rgb%%,*}
  rest=${rgb#*,}
  green=${rest%%,*}
  blue=${rest#*,}
  blue=${blue%%,*}
  case "${red}${green}${blue}" in
    '' | *[!0-9]*) ;;
    *)
      luma=$(((red * 299 + green * 587 + blue * 114) / 1000))
      if [ "${luma}" -lt 128 ]; then
        current=dark
      else
        current=light
      fi
      return 0
      ;;
  esac

  # No explicit colors in kdeglobals: fall back to the scheme name.
  scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2> /dev/null)
  case "${scheme}" in
    *[Dd]ark*) current=dark ;;
    ?*) current=light ;;
    *) ;;
  esac
}

query_state() {
  value=
  if [ -r "${state_file}" ]; then
    read -r value < "${state_file}"
  fi
  case "${value}" in
    light | dark) current=${value} ;;
    *) ;;
  esac
}

# Ask the most authoritative source first: Plasma when in a Plasma session,
# otherwise DMS, then GTK settings, then KDE, then our own last-applied state.
detect_mode() {
  current=
  if session_is KDE; then
    query_kde
  fi
  if [ -z "${current}" ]; then
    query_dms
  fi
  if [ -z "${current}" ]; then
    query_gsettings
  fi
  if [ -z "${current}" ]; then
    query_kde
  fi
  if [ -z "${current}" ]; then
    query_state
  fi
}

# ------------------------------------------------------------- backends ---

apply_dms() {
  if have dms; then
    dms ipc call theme "${1}" > /dev/null 2>&1
  fi
  return 0
}

apply_gsettings() {
  have gsettings || return 0
  if [ "${1}" = light ]; then
    gtk_theme="${THEME_GTK_LIGHT:-}"
    icon_theme="${THEME_ICONS_LIGHT:-}"
  else
    gtk_theme="${THEME_GTK_DARK:-}"
    icon_theme="${THEME_ICONS_DARK:-}"
  fi
  gsettings set org.gnome.desktop.interface color-scheme "prefer-${1}" > /dev/null 2>&1
  if [ -n "${gtk_theme}" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "${gtk_theme}" > /dev/null 2>&1
  fi
  if [ -n "${icon_theme}" ]; then
    gsettings set org.gnome.desktop.interface icon-theme "${icon_theme}" > /dev/null 2>&1
  fi
  return 0
}

apply_kde() {
  if [ "${1}" = light ]; then
    kde_scheme="${THEME_KDE_SCHEME_LIGHT:-BreezeLight}"
    kde_laf="${THEME_KDE_LOOKANDFEEL_LIGHT:-}"
  else
    kde_scheme="${THEME_KDE_SCHEME_DARK:-BreezeDark}"
    kde_laf="${THEME_KDE_LOOKANDFEEL_DARK:-}"
  fi
  if [ -n "${kde_laf}" ] && have plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel --apply "${kde_laf}" > /dev/null 2>&1
  elif have plasma-apply-colorscheme; then
    plasma-apply-colorscheme "${kde_scheme}" > /dev/null 2>&1
  fi
  return 0
}

apply_xfce() {
  have xfconf-query || return 0
  session_is XFCE || return 0
  if [ "${1}" = light ]; then
    xfce_theme="${THEME_XFCE_LIGHT:-Greybird}"
  else
    xfce_theme="${THEME_XFCE_DARK:-Greybird-dark}"
  fi
  xfconf-query -c xsettings -p /Net/ThemeName -s "${xfce_theme}" > /dev/null 2>&1
  return 0
}

run_hooks() {
  [ -d "${hook_dir}" ] || return 0
  for hook in "${hook_dir}"/*; do
    if [ -f "${hook}" ] && [ -x "${hook}" ]; then
      "${hook}" "${1}" > /dev/null 2>&1
    fi
  done
  return 0
}

save_state() {
  if mkdir -p "${state_dir}" 2> /dev/null; then
    printf '%s\n' "${1}" > "${state_file}"
  fi
  return 0
}

# Apply "${1}" (light|dark) to everything we can find.
set_mode() {
  apply_dms "${1}"
  apply_gsettings "${1}"
  apply_kde "${1}"
  apply_xfce "${1}"
  run_hooks "${1}"
  save_state "${1}"
}

# --------------------------------------------------------------- actions ---

toggle_manual() {
  detect_mode
  if [ "${current}" = dark ]; then
    target=light
  else
    target=dark
  fi
  set_mode "${target}"
  announce "${target}"
}

force_mode() {
  set_mode "${1}"
  announce "${1}"
}

# Safe to run from a timer: only touches things when the mode has to change.
auto_time() {
  hour=$(date +%H)
  if [ "${hour}" -ge "${THEME_LIGHT_START}" ] && [ "${hour}" -lt "${THEME_DARK_START}" ]; then
    target=light
  else
    target=dark
  fi
  detect_mode
  if [ "${current}" != "${target}" ]; then
    set_mode "${target}"
  fi
}

show_status() {
  detect_mode
  printf 'Current mode : %s\n' "${current:-unknown}"
  printf 'Auto schedule: light from %s:00, dark from %s:00\n' "${THEME_LIGHT_START}" "${THEME_DARK_START}"
  printf 'Hooks dir    : %s\n' "${hook_dir}"
  printf 'Tools found  :'
  for tool in dms plasma-apply-colorscheme plasma-apply-lookandfeel kreadconfig6 gsettings xfconf-query notify-send; do
    if have "${tool}"; then
      printf ' %s' "${tool}"
    fi
  done
  printf '\n'
}

usage() {
  cat << EOF
Usage: ${0##*/} [OPTION]

  -t, --toggle   flip between light and dark (default)
  -l, --light    switch to light
  -d, --dark     switch to dark
  -a, --auto     pick light/dark from the time of day (timer/cron friendly)
  -s, --status   show detected mode and available tools
  -h, --help     show this help
EOF
}

case "${1:-}" in
  --toggle | -t | '') toggle_manual ;;
  --light | -l) force_mode light ;;
  --dark | -d) force_mode dark ;;
  --auto | -a) auto_time ;;
  --status | -s) show_status ;;
  --help | -h) usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
