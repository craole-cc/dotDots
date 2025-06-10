#! /bin/sh

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
  USER_UID="$(
    powershell -NoProfile -Command "[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value" 2>/dev/null |
      tr -d '\r\n'
  )"
  #{ Use the user's SID to get the path for the Recycle Bin }
  if [ -n "${USER_UID}" ]; then
    #? User's personal Recycle Bin
    manage_env --set --var TRASH --val "${SYSTEMDRIVE}/\$Recycle.Bin/${USER_UID}"
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
manage_env --force --set --var DATA_HOME --val "${DATA_HOME}"
manage_env --force --set --var CACHE_HOME --val "${CACHE_HOME}"
manage_env --force --set --var CONFIG_HOME --val "${CONFIG_HOME}"
manage_env --force --set --var STATE_HOME --val "${STATE_HOME}"
manage_env --force --set --var RUNTIME_DIR --val "${RUNTIME_DIR}"
manage_env --force --set --var USER_UID --val "${USER_UID}"
manage_env --force --set --var TRASH --val "${TRASH}"

#|->  Home Directories
manage_env --force --set --var DOCUMENTS --val "${HOME}/Documents"
manage_env --force --set --var DOWNLOADS --val "${HOME}/Downloads"
manage_env --force --set --var PICTURES --val "${HOME}/Pictures"
manage_env --force --set --var MUSIC --val "${HOME}/Music"
manage_env --force --set --var VIDEOS --val "${HOME}/Videos"

#|->  Wallpapers
if [ -d "${PICTURES:?}/Wallpapers" ]; then
  WALLPAPERS="${PICTURES}/Wallpapers"
elif [ -d "${HOME}/Pictures/wallpapers" ]; then
  WALLPAPERS="${HOME}/Pictures/wallpapers"
elif [ -d "${DOTS_RES:?}/Images/wallpaper" ]; then
  WALLPAPERS="${DOTS_RES}/Images/wallpaper"
fi

if [ -n "${WALLPAPERS}" ]; then
  manage_env --set --var WALLPAPERS --val "${WALLPAPERS}"
fi
