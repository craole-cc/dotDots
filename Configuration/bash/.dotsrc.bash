#!/bin/bash

echo "Loading ~/.bashrc"
#{ If not running interactively, don't do anything }
if [[ $- != *i* ]]; then return; fi

echo "Loaded ~/.bashrc"
# #{ Install/update ble.sh }
# if [[ -z "${_ble_bash:-}" ]]; then
#   _ble_bash="${HOME}/.local/share/blesh/ble.sh"
#   if [[ -f "${_ble_bash}" ]]; then
#     source "${_ble_bash}"
#   fi
# fi

#{ Enable Ble.sh for syntax highlighting, auto suggestions, etc. }
# blesh="${HOME}/.local/share/blesh/ble.sh"
# blesh_rc_dots="${DOTS:-}/Configuration/bash/scripts/blesh.bash"
# blesh_rc_home="${HOME}/.blerc"
# if [[ -f "${blesh_rc_dots}" ]]; then
#   source "${blesh}" --noattach --rcfile "${blesh_rc_dots}"
# elif [[ -f "${blesh_rc_home}" ]]; then
#   source "${blesh}" --noattach --rcfile "${blesh_rc_home}"
# else
#   source "${blesh}"
# fi

# [[ -z ${BLE_VERSION-} ]] || ble-attach
