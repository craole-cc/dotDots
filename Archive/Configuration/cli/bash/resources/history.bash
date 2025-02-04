#!/usr/bin/env bash
#==================================================
#
# CONFIG - HISTORY
# CLI/config/bash/resources/history.zsh
#
#==================================================

# _______________________________________ OPTIONS<|

# shopt -s histreedit
shopt -s cmdhist

# Set the maximum number of commands to keep in the history
HISTSIZE=10000

# Append commands to the history file as soon as they are executed
shopt -s histappend

# Ignore duplicate commands and commands starting with spaces in the history
HISTCONTROL=ignoreboth

# Ignore specific commands from being recorded in the history
HISTIGNORE="ls:cd:clear"

# Disable command history timestamp
HISTTIMEFORMAT=""

# Set the maximum number of lines to save in the history file
HISTFILESIZE=20000

# Ignore commands that have leading whitespace in the history file
HISTIGNORE="[ ]*"

# Increase the history file size limit
if [ -z "$PROMPT_COMMAND" ]; then
    PROMPT_COMMAND="history -a; history -n"
else
    PROMPT_COMMAND="${PROMPT_COMMAND}; history -a; history -n"
fi
