#! /bin/sh
# shellcheck disable=SC2034,SC2154,SC1091

#{ Output Control }
manage_env force --var DELIMITER --val "${DELIMITER:-"$(printf "\037")"}"
manage_env force --var VERBOSITY --val "$(verbosity "${VERBOSITY:-"Error"}" || true)"
manage_env force --var VERBOSITY_QUIET --val "$(verbosity "${VERBOSITY_QUIET:-"Quiet"}" 0 || true)"
manage_env force --var VERBOSITY_ERROR --val "$(verbosity "${VERBOSITY_ERROR:-"Error"}" 1 || true)"
manage_env force --var VERBOSITY_WARN --val "$(verbosity "${VERBOSITY_WARN:-"Warn"}" 2 || true)"
manage_env force --var VERBOSITY_INFO --val "$(verbosity "${VERBOSITY_INFO:-"Info"}" 3 || true)"
manage_env force --var VERBOSITY_DEBUG --val "$(verbosity "${VERBOSITY_DEBUG:-"Debug"}" 4 || true)"
manage_env force --var VERBOSITY_TRACE --val "$(verbosity "${VERBOSITY_TRACE:-"Trace"}" 5 || true)"

#{ System Information }
manage_env force --var USER_NAME --val "$(get_os_user || true)"
manage_env force --var USER --val "${USER_NAME}"
manage_env force --var SHELL --val "${SHELL:-"$(get_os_shell || true)"}"
manage_env force --var USER_SHELL --val "${SHELL}"
manage_env force --var SYS_TYPE --val "$(os.type.fetch || true)"
manage_env force --var SYS_NAME --val "$(os.distro.fetch || true)"
manage_env force --var SYS_KERN --val "$(os.kernel.fetch || true)"
manage_env force --var SYS_ARCH --val "$(os.arch.fetch || true)"
manage_env force --var SYS_HOST --val "$(hostname.fetch || true)"
manage_env force --var SYS_INFO --val "${SYS_TYPE} ${SYS_NAME} | ${SYS_KERN} | ${SYS_ARCH} | ${USER_NAME}@${SYS_HOST}"

case "${SYS_TYPE:-}" in
Windows)
  DATA_HOME="${APPDATA:-"${HOME}/AppData/Roaming"}"     # powershell \$env:APPDATA
  CACHE_HOME="${LOCALAPPDATA:-"${HOME}/AppData/Local"}" # powershell \$env:LOCALAPPDATA
  CONFIG_HOME="${DATA_HOME}"
  STATE_HOME="${CACHE_HOME}"
  RUNTIME_DIR="${TEMP:-"${LOCALAPPDATA}/Temp"}" # Windows temp directory
  # Get user's SID for personal Recycle Bin
  user_sid="$(powershell -NoProfile -Command "[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value")"
  TRASH="${SYSTEMDRIVE}/\$Recycle.Bin/${user_sid}" # User's personal Recycle Bin
  ;;
*)
  DATA_HOME="${XDG_DATA_HOME:-"${HOME}/.local/share"}"
  CACHE_HOME="${XDG_CACHE_HOME:-"${HOME}/.cache"}"
  CONFIG_HOME="${XDG_CONFIG_HOME:-"${HOME}/.config"}"
  STATE_HOME="${XDG_STATE_HOME:-"${HOME}/.local/state"}"
  RUNTIME_DIR="${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}"
  TRASH="${DATA_HOME}/Trash/files"
  ;;
esac
manage_env --force --var DATA_HOME --val "${DATA_HOME}"
manage_env --force --var CACHE_HOME --val "${CACHE_HOME}"
manage_env --force --var CONFIG_HOME --val "${CONFIG_HOME}"
manage_env --force --var STATE_HOME --val "${STATE_HOME}"
manage_env --force --var RUNTIME_DIR --val "${RUNTIME_DIR}"
manage_env --force --var TRASH --val "${TRASH}"

#{ User Directories }
manage_env --var DOCUMENTS --val "${HOME}/Documents"
manage_env --var DOWNLOADS --val "${HOME}/Downloads"
manage_env --var PICTURES --val "${HOME}/Pictures"
manage_env --var MUSIC --val "${HOME}/Music"
manage_env --var VIDEOS --val "${HOME}/Videos"
if [ -d "${PHOTOS}/Wallpapers" ]; then
  WALLPAPERS="$(printf "%s" "${PHOTOS}/Wallpapers")"
elif [ -d "${HOME}/Pictures/wallpapers" ]; then
  WALLPAPERS="$(printf "%s" "${HOME}/Pictures/wallpapers")"
else
  WALLPAPERS="$(printf "%s" "${DOTS_RES}/Images/wallpaper")"
fi
manage_env --var WALLPAPERS --val "${WALLPAPERS}"

#{ General }
manage_env --force --var TIMESTAMP_FMT --val "%Y-%m-%d_%H-%M-%S"
