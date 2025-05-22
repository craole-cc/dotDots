# shellcheck disable=SC2148

#@ If not running interactively, don't do anything
case "$-" in *i*) ;; *) return ;; esac

#@ History Settings
HISTSIZE=10000                                  #? Maximum events in memory
HISTFILESIZE=20000                              #? Maximum events in history file
HISTCONTROL=ignoreboth:erasedups:ignorefail     #? Only add successful commands to history
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear" #? Don't record these commands
shopt -s histappend                             #? Append to history instead of overwriting
PROMPT_COMMAND="history -n; history -w; history -c; history -r; ${PROMPT_COMMAND}"

#@ Launch .profile, if it exists
USER_RC="${HOME}/.profile"
if [[ ! -f "${USER_RC}" ]]; then :; else
  export USER_RC
  # shellcheck disable=SC1090
  source "${USER_RC}"
fi

#@ Better directory navigation
shopt -s autocd     #? Type directory name to cd into it
shopt -s cdspell    #? Autocorrect minor spelling errors in cd
shopt -s dirspell   #? Autocorrect directory spelling
shopt -s nocaseglob #? Case-insensitive globbing

#@ Command line editing
shopt -s cmdhist                       #? Save multi-line commands in one history entry
bind '"\e[A": history-search-backward' #? Up arrow for history search
bind '"\e[B": history-search-forward'  #? Down arrow for history search
