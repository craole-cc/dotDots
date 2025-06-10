#!/bin/sh

#{ Determine shell and set history file }
SHELL_TYPE="$(
  basename "${SHELL_TYPE:-"${SHELL:-}"}" |
    tr '[:upper:]' '[:lower:]'
)"
case "${SHELL_TYPE:-}" in
bash) shell_ext=".bash" ;;
zsh) shell_ext=".zsh" ;;
sh) shell_ext=".sh" ;;
*) shell_ext="" ;;
esac

#{ History file location }
: "${DOTS_TMP:="${DOTS}/.cache"}"
HISTFILE="${DOTS_TMP}/history${shell_ext}"

#{ History size limits }
HISTSIZE=100000000   #? Maximum events in memory
SAVEHIST=${HISTSIZE} #? Events to save

#{ Export history variables }
export HISTFILE HISTSIZE SAVEHIST

#{ Define a function to synchronize history }
histup() {
  fc -W #? Write current history to file
  fc -R #? Read history from file
}
