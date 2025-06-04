#!/bin/sh

HISTFILE="${DOTS_TMP:-"${DOTS}/.cache"}/history"
HISTFILESIZE=100000000
HISTSIZE=100000000
SAVEHIST=${HISTSIZE}
HISTTIMEFORMAT='%F %T '
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:ll:cd:pwd:bg:fg:history:clear:history -a:history -n:history -r: history -c"
export HISTFILE HISTFILESIZE HISTSIZE SAVEHIST HISTTIMEFORMAT HISTCONTROL HISTIGNORE

updateHistory() {
  history -a
  history -n
  history -r
  # history -c
}

updateHistory
