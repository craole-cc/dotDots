#!/bin/sh

# #@ Set default if not set
# : "${RC:=_.sh}"
# : "${EDITOR:=hx}"

# # shellcheck disable=SC1090,SC2034,SC2139,SC2154,SC2163
# register_path() {
#   var=$1
#   val=$2

#   #@ Set and export variable if not already set
#   eval '[ -z "${'"${var}"'}" ] && '"${var}"'="$val"'
#   eval 'export '"${var}"

#   #@ Define the edit function for files and directories
#   eval "ed_${var}() { \"\$EDITOR\" \"\${${var}}\"; }"

#   #@ Define the cd function for directories and entrypoint sourcing
#   eval 'dir="${'"${var}"'}"'
#   if [ -d "${dir}" ]; then
#     eval "cd_${var}() { cd \"\${${var}}\"; }"

#     #@ Source entrypoint if it exists
#     if [ -f "${dir}/${RC}" ]; then
#       . "${dir}/${RC}"
#     fi
#   fi
# }

# #@ Initialize top-level directories and files
# register_path HOME "${HOME:?}"
# register_path DOTS "${DOTS:?}"
# register_path DOTS_ENV "${DOTS}/Environment"
# register_path DOTS_BIN "${DOTS}/Bin"
# register_path DOTS_CFG "${DOTS}/Configuration"
# register_path DOTS_DLD "${DOTS}/Downloads"
# register_path DOTS_DOC "${DOTS}/Documentation"
# register_path DOTS_NIX "${DOTS}/Admin"
# register_path DOTS_TMP "${DOTS}.cache"
# register_path DOTS_BIN "${HOME}/dotfiles/Bin"
