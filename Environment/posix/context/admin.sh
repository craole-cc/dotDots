#! /bin/sh
# shellcheck disable=SC2034,SC2154,SC1091

#|->  Output Control
manage_env --set --var DELIMITER --val "${DELIMITER:-"$(printf "\037")"}"
manage_env --set --var VERBOSITY --val "$(verbosity "${VERBOSITY:-"Error"}" || true)"
manage_env --set --var VERBOSITY_QUIET --val "$(verbosity "${VERBOSITY_QUIET:-"Quiet"}" 0 || true)"
manage_env --set --var VERBOSITY_ERROR --val "$(verbosity "${VERBOSITY_ERROR:-"Error"}" 1 || true)"
manage_env --set --var VERBOSITY_WARN --val "$(verbosity "${VERBOSITY_WARN:-"Warn"}" 2 || true)"
manage_env --set --var VERBOSITY_INFO --val "$(verbosity "${VERBOSITY_INFO:-"Info"}" 3 || true)"
manage_env --set --var VERBOSITY_DEBUG --val "$(verbosity "${VERBOSITY_DEBUG:-"Debug"}" 4 || true)"
manage_env --set --var VERBOSITY_TRACE --val "$(verbosity "${VERBOSITY_TRACE:-"Trace"}" 5 || true)"

#|->  System Information
manage_env --set --var USER --val "$(get_os_user || true)"
manage_env --set --var SHELL --val "${SHELL:-"$(get_os_shell || true)"}"
manage_env --set --var SHELL_TYPE --val "$(basename "${SHELL}")"
manage_env --set --var SYS_TYPE --val "$(os.type.fetch || true)"
manage_env --set --var SYS_NAME --val "$(os.distro.fetch || true)"
manage_env --set --var SYS_KERN --val "$(os.kernel.fetch || true)"
manage_env --set --var SYS_ARCH --val "$(os.arch.fetch || true)"
manage_env --set --var SYS_HOST --val "$(hostname.fetch || true)"
manage_env --set --var SYS_INFO \
  --val "${SYS_TYPE:?} ${SYS_NAME:?} | ${SYS_KERN:?} | ${SYS_ARCH:?} | ${USER:?}@${SYS_HOST:?}"

#|->  User Directories
case "${SYS_TYPE:-}" in
Windows)
  DATA_HOME="${APPDATA:-"${HOME}/AppData/Roaming"}"     #? powershell \$env:APPDATA
  CACHE_HOME="${LOCALAPPDATA:-"${HOME}/AppData/Local"}" #? powershell \$env:LOCALAPPDATA
  CONFIG_HOME="${DATA_HOME}"
  STATE_HOME="${CACHE_HOME}"
  RUNTIME_DIR="${TEMP:-"${LOCALAPPDATA}/Temp"}" #? Windows temp directory
  USER_UID="$(id -u 2>/dev/null)"

  #{ Ensure SYSTEMDRIVE is set }
  SYSTEMDRIVE="${SYSTEMDRIVE:-"$(
    powershell -NoProfile -Command "[System.Environment]::SystemDirectory.Substring(0,2)" 2>/dev/null |
      tr -d '\r\n'
  )"}"
  if [ -z "${SYSTEMDRIVE}" ]; then
    #{ Try to deduce from SYSTEMROOT if available }
    if [ -n "${SYSTEMROOT}" ]; then
      SYSTEMDRIVE="${SYSTEMROOT%%\\*}"
    else
      #{ As a last resort, fall back to C: }
      SYSTEMDRIVE="C:"
    fi
  fi

  #{ Get user's SID for personal Recycle Bin }
  USER_SID="$(
    powershell -NoProfile -Command "[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value" 2>/dev/null |
      tr -d '\r\n'
  )"
  #{ Use the user's SID to get the path for the Recycle Bin }
  if [ -n "${USER_SID}" ]; then
    TRASH="${SYSTEMDRIVE}/\$Recycle.Bin/${USER_SID}" #? User's personal Recycle Bin
  else
    TRASH=""
  fi
  ;;
*)
  USER_UID="$(id -u)"
  DATA_HOME="${XDG_DATA_HOME:-"${HOME}/.local/share"}"
  CACHE_HOME="${XDG_CACHE_HOME:-"${HOME}/.cache"}"
  CONFIG_HOME="${XDG_CONFIG_HOME:-"${HOME}/.config"}"
  STATE_HOME="${XDG_STATE_HOME:-"${HOME}/.local/state"}"
  RUNTIME_DIR="${XDG_RUNTIME_DIR:-"/run/user/${USER_UID}"}"
  TRASH="${DATA_HOME}/Trash/files"
  ;;
esac
manage_env --set --var DATA_HOME --val "${DATA_HOME}"
manage_env --set --var CACHE_HOME --val "${CACHE_HOME}"
manage_env --set --var CONFIG_HOME --val "${CONFIG_HOME}"
manage_env --set --var STATE_HOME --val "${STATE_HOME}"
manage_env --set --var RUNTIME_DIR --val "${RUNTIME_DIR}"
manage_env --set --var TRASH --val "${TRASH}"
manage_env --set --var USER_UID --val "${USER_UID}"

#|->  Home Directories
manage_env --set --var DOCUMENTS --val "${HOME}/Documents"
manage_env --set --var DOWNLOADS --val "${HOME}/Downloads"
manage_env --set --var PICTURES --val "${HOME}/Pictures"
manage_env --set --var MUSIC --val "${HOME}/Music"
manage_env --set --var VIDEOS --val "${HOME}/Videos"
if [ -d "${PHOTOS}/Wallpapers" ]; then
  WALLPAPERS="$(printf "%s" "${PHOTOS}/Wallpapers")"
elif [ -d "${HOME}/Pictures/wallpapers" ]; then
  WALLPAPERS="$(printf "%s" "${HOME}/Pictures/wallpapers")"
else
  WALLPAPERS="$(printf "%s" "${DOTS_RES}/Images/wallpaper")"
fi
manage_env --set --var WALLPAPERS --val "${WALLPAPERS}"

#|->  Browser
case "${SYS_TYPE}" in
Windows)
  browser_id=$(
    reg query "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" |
      awk '/ProgId/ {print $3}'
  )
  browser_cmd=$(reg query "HKCR\\${browser_id}\\shell\\open\\command" | awk -F'    ' '/REG_SZ/ {print $4}')
  browser_path=$(printf "%s" "${browser_cmd}" | sed -n 's/.*"\(.*\)".*/\1/p')
  browser="${browser_paths:-"$(browser-edge --set 2>/dev/null)"}"
  ;;
*)
  browser_path="xdg-open"
  ;;
esac
manage_env --set --var BROWSER --val "${browser_path:-"firefox"}"

#{ General }
manage_env --set --var TIMESTAMP_FMT --val "%Y-%m-%d_%H-%M-%S"
