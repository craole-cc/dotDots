#!/usr/bin/env zsh

#==================================================
#
# ZSHRC - HISTORY
# CLI/config/zsh/resources/history.zsh
#
#==================================================

# ________________________________________ WIDGET<|

# --> Open Dir in LF
lfcd() {
  tmp="$(mktemp)"
  lf -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir="$(cat "$tmp")"
    rm -f "$tmp" >/dev/null
    [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
  fi
}

[ "$OS_SHELL" = zsh ] &&
  bindkey -s '^o' 'lfcd\n' # >>= ctrl + o
[ "$OS_SHELL" = bash ] &&
  bind -s '^o' 'lfcd\n' # >>= ctrl + o

# __________________________________________ KEYS<|

# _______________________________________ OPTIONS<|
