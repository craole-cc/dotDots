#!/usr/bin/env zsh
#==================================================
#
# ZSH_HISTORY
# CLI/config/zsh/resources/history.zsh
#
#==================================================

# ________________________________________ EXPORT<|

set -a # --> Export <begin>
HISTFILE="$ZDOTDIR/.zsh_history"
HISTFILESIZE=1000000000
HISTSIZE=1000000000
HISTTIMEFORMAT="[%F %T] "
SAVEHIST=$HISTSIZE
set +a # --> Export <end>

# ________________________________________ WIDGET<|

# |> ZLE Widget 1
# up-line-or-beginning-local-search() {
#   if [[ $LBUFFER == *$'\n'* ]]; then
#     zle up-line-or-history
#     __searching=''
#   elif [[ -n $PREBUFFER ]] &&
#       zstyle -t ':zle:up-line-or-beginning-search' edit-buffer
#   then
#     zle push-line-or-edit
#   else
#     [[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor
#     __savecursor=$CURSOR
#     __searching=$WIDGET
#     zle set-local-history 1
#     zle history-beginning-search-backward
#     zle set-local-history 0
#     zstyle -T ':zle:up-line-or-beginning-search' leave-cursor &&
#         zle end-of-line
#   fi
# }
# zle -N up-line-or-beginning-local-search

# down-line-or-beginning-local-search() {
#   if [[ ${+NUMERIC} -eq 0 &&
#       ( $LASTWIDGET = $__searching || $RBUFFER != *$'\n'* ) ]]
#   then
#     [[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor
#     __searching=$WIDGET
#     __savecursor=$CURSOR

#     zle set-local-history 1
#     if zle history-beginning-search-forward; then
#       zle set-local-history 0
#       [[ $RBUFFER = *$'\n'* ]] ||
#         zstyle -T ':zle:down-line-or-beginning-search' leave-cursor &&
#         zle end-of-line
#       return
#     fi
#     zle set-local-history 0

#     [[ $RBUFFER = *$'\n'* ]] || return
#   fi
#   __searching=''
#   zle down-line-or-history
# }
# zle -N down-line-or-beginning-local-search

# |> ZLE Widget 2
up-line-or-local-history() {
  zle set-local-history 1
  zle up-line-or-history
  zle set-local-history 0
}
zle -N up-line-or-local-history
down-line-or-local-history() {
  zle set-local-history 1
  zle down-line-or-history
  zle set-local-history 0
}
zle -N down-line-or-local-history

# __________________________________________ KEYS<|
# |> All
# see CLI/config/zsh/resources/keys.zsh
# _______________________________________ OPTIONS<|

# |> Options
# --> Save Time
unsetopt INC_APPEND_HISTORY      # --> Immediate
unsetopt INC_APPEND_HISTORY_TIME # --> After command
setopt EXTENDED_HISTORY          # --> Remove Timestamp to match Bash
setopt SHARE_HISTORY             # --> Immediate and across sessions

# --> Duplicates
setopt HIST_EXPIRE_DUPS_FIRST # --> Remove Old Duplicates
setopt HIST_SAVE_NO_DUPS      # --> Skip Duplicates
setopt HIST_FIND_NO_DUPS      # --> Skip Duplicates
setopt HIST_REDUCE_BLANKS     # --> Remove superfluous blanks

# --> Privacy
setopt HIST_IGNORE_SPACE
