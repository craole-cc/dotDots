#!/bin/sh

#==================================================
#
# HISTORY
# CLI/bin/environment/admin/history.sh
#
#==================================================

# _______________________________________ GENREAL<|

HISTFILE="$DOTS/Logs/history"
HISTFILESIZE=100000000
HISTSIZE=100000000
SAVEHIST=$HISTSIZE
HISTTIMEFORMAT='%F %T '
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:ll:cd:pwd:bg:fg:history:clear:history -a:history -n:history -r: history -c"

updateHistory() {
  history -a
  history -n
  history -r
  # history -c
}

# updateHistory