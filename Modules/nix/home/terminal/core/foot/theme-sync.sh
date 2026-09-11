set -euo pipefail

colors_source() {
  printf '%s\n' "${DMS_COLORS_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}"
}

runtime_colors() {
  printf '%s\n' "${FOOT_DMS_COLORS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/foot/dotdots-dms-colors.ini}"
}

write_fallback() {
  local output dir tmp
  output="$(runtime_colors)"
  dir="${output%/*}"
  mkdir -p "$dir"
  tmp="$(mktemp "${output}.new.XXXXXX")"
  cat >"$tmp" <<'PALETTE'
[colors-dark]
background=303446
foreground=c6d0f5
alpha=0.95

[colors-light]
background=eff1f5
foreground=4c4f69
alpha=0.95
PALETTE
  chmod 0644 "$tmp"
  mv -f "$tmp" "$output"
}

render_dms() {
  local source output dir tmp
  source="$(colors_source)"
  output="$(runtime_colors)"
  [ -s "$source" ] || return 1

  dir="${output%/*}"
  mkdir -p "$dir"
  tmp="$(mktemp "${output}.new.XXXXXX")"

  if ! jq -er '
    def hex: sub("^#"; "");
    def dank_dark($index): .dank16[("color" + ($index | tostring))].dark | hex;
    def dank_light($index): .dank16[("color" + ($index | tostring))].light | hex;
    [
      "[colors-dark]",
      "foreground=\(.colors.dark.on_surface | hex)",
      "background=\(.colors.dark.background | hex)",
      "selection-foreground=\(.colors.dark.on_surface | hex)",
      "selection-background=\(.colors.dark.primary_container | hex)",
      "cursor=\(.colors.dark.background | hex) \(.colors.dark.primary | hex)",
      (range(0; 8) as $i | "regular\($i)=\(dank_dark($i))"),
      (range(8; 16) as $i | "bright\($i - 8)=\(dank_dark($i))"),
      "alpha=0.95",
      "dim-blend-towards=black",
      "",
      "[colors-light]",
      "foreground=\(.colors.light.on_surface | hex)",
      "background=\(.colors.light.background | hex)",
      "selection-foreground=\(.colors.light.on_surface | hex)",
      "selection-background=\(.colors.light.primary_container | hex)",
      "cursor=\(.colors.light.background | hex) \(.colors.light.primary | hex)",
      (range(0; 8) as $i | "regular\($i)=\(dank_light($i))"),
      (range(8; 16) as $i | "bright\($i - 8)=\(dank_light($i))"),
      "alpha=0.95",
      "dim-blend-towards=white"
    ] | .[]
  ' "$source" >"$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if [ -f "$output" ] && cmp -s "$tmp" "$output"; then
    rm -f "$tmp"
    return 2
  fi

  chmod 0644 "$tmp"
  mv -f "$tmp" "$output"
  return 0
}

prepare() {
  local rc
  if render_dms; then
    return 0
  else
    rc=$?
  fi

  if [ "$rc" -eq 2 ] || [ -s "$(runtime_colors)" ]; then
    return 0
  fi

  write_fallback
}

current_mode() {
  local mode
  if command -v dms >/dev/null 2>&1; then
    mode="$(dms ipc call theme getMode 2>/dev/null || true)"
    case "$mode" in
      *light*)
        printf '%s\n' light
        return 0
        ;;
      *dark*)
        printf '%s\n' dark
        return 0
        ;;
    esac
  fi
  return 1
}

signal_foot() {
  local mode signal pids
  mode="$1"
  case "$mode" in
    dark) signal=USR1 ;;
    light) signal=USR2 ;;
    *) return 0 ;;
  esac

  pids="$(pgrep -x foot 2>/dev/null || true)"
  [ -n "$pids" ] || return 0
  # shellcheck disable=SC2086
  kill -"$signal" $pids 2>/dev/null || true
}

restart_server_if_idle() {
  if pgrep -x footclient >/dev/null 2>&1; then
    return 1
  fi
  if ! systemctl --user is-active --quiet foot.service 2>/dev/null; then
    return 1
  fi
  systemctl --user restart foot.service
}

sync_once() {
  local mode
  prepare
  mode="$(current_mode || true)"
  [ -n "$mode" ] && signal_foot "$mode"
}

monitor() {
  local mode last_mode palette_pending rc
  prepare
  last_mode=""
  palette_pending=1

  while :; do
    if render_dms; then
      palette_pending=1
    else
      rc=$?
      if [ "$rc" -ne 1 ] && [ "$rc" -ne 2 ]; then
        printf 'feet-theme-sync: palette render failed (%s)\n' "$rc" >&2
      fi
    fi

    mode="$(current_mode || true)"
    if [ -n "$mode" ] && [ "$mode" != "$last_mode" ]; then
      signal_foot "$mode"
      last_mode="$mode"
    fi

    if [ "$palette_pending" -eq 1 ]; then
      if restart_server_if_idle; then
        palette_pending=0
        [ -n "$mode" ] && signal_foot "$mode"
      elif ! pgrep -x foot >/dev/null 2>&1; then
        palette_pending=0
      fi
    fi

    sleep 2
  done
}

case "${1:-sync}" in
  prepare | render)
    prepare
    ;;
  sync)
    sync_once
    ;;
  monitor)
    monitor
    ;;
  mode)
    current_mode
    ;;
  *)
    printf 'Usage: feet-theme-sync {prepare|sync|monitor|mode}\n' >&2
    exit 2
    ;;
esac
