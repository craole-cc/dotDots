#!/usr/bin/env bash
#==================================================
#
# CONFIG - COMPLETION
# CLI/config/bash/resources/completion.bash
#
#==================================================

# _______________________________________ OPTIONS<|

BASH_COMPLETION="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completioins"
mkdir --parents "$BASH_COMPLETION"

# case "$sys_INFO" in
# *Windows*)
#   BASH_COMPLETION="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completioins"
#   mkdir --parents "$BASH_COMPLETION"
#   ;;
# *)
#   if [ -r /usr/share/bash-completion/bash_completion ]; then
#     BASH_COMPLETION="/usr/share/bash-completion/bash_completion"
#   elif [ -r /etc/bash_completion ]; then
#     BASH_COMPLETION="/etc/bash_completion"
#   fi
#   ;;
# esac

# Use bash-completion, if available
if ! shopt -oq posix; then
  [[ $PS1 && -f "$BASH_COMPLETION" ]] &&
    . "$BASH_COMPLETION"
fi
