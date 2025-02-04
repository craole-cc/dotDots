#!/usr/bin/env bash
#==================================================
#
# CONFIG - COMPLETION
# CLI/config/bash/resources/completion.bash
#
#==================================================

# _______________________________________ OPTIONS<|

if [ -r /usr/share/bash-completion/bash_completion ]; then
  BASH_COMPLETION="/usr/share/bash-completion/bash_completion"
elif [ -r /etc/bash_completion ]; then
  BASH_COMPLETION="/etc/bash_completion"
fi

rustup --version >/dev/null 2>&1 &&
  rustup completions bash >"$BDOTDIR/functions/rustup"

#@ Use bash-completion, if available
if ! shopt -oq posix; then
  [[ $PS1 && -f "$BASH_COMPLETION" ]] && . "$BASH_COMPLETION"
fi
