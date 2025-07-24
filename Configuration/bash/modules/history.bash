#!/bin/bash

#{ Set the history file location }
if [[ -n "${DOTS_CACHE:-}" ]]; then
  mkdir -p "${DOTS_CACHE}"
  touch "${DOTS_CACHE}/history.bash"
  export HISTFILE="${DOTS_CACHE}/history.bash"
fi

#{ Append commands to the history file as soon as they are executed }
shopt -s histappend

#{ Allow the user to re-edit a failed history substitution }
shopt -s histreedit

#{ Allow multiline commands to be added to the history file as a single entry }
shopt -s cmdhist

#{ Allow unlimited history expansion }
HISTSIZE=-1
HISTFILESIZE=-1

#{ Ignore duplicate commands and commands starting with spaces in the history }
HISTCONTROL=ignoreboth:erasedups

#{ Ignore specific commands from being recorded in the history }
HISTIGNORE="ls:cd:clear:[ \t]*" #? Common commands and commands starting with spaces

#{ Disable command history timestamp }
# HISTTIMEFORMAT="%F %T" # add timestamp to history

#{ Increase the history file size limit
if [[ -z "${PROMPT_COMMAND}" ]]; then
  PROMPT_COMMAND="history -a; history -n"
else
  PROMPT_COMMAND="${PROMPT_COMMAND}; history -a; history -n"
fi

#{ Enable Atuin for history management, if installed }
if command -v atuin >/dev/null 2>&1; then
  atuin_cmd="$(atuin init bash --disable-up-arrow --disable-down-arrow)"
  eval "${atuin_cmd}"
fi
