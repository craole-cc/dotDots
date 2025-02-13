#!/usr/bin/env bash

command -v weHave >/dev/null 2>&1 ||
  weHave() {
    command -v "$1" >/dev/null 2>&1 || return
  }

init_PS1() {
  # git dirty functions for prompt
  parse_git_dirty() {
    [[ $(git status --porcelain 2>/dev/null) ]] && echo "*"
  }

  # This function is called in your prompt to output your active git branch.
  parse_git_branch() {
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
  }

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
  esac

  if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
  fi

  if [ "$color_prompt" = yes ]; then
    RED="\[\033[0;31m\]"       # This syntax is some weird bash color thing I never
    LIGHT_RED="\[\033[1;31m\]" # really understood
    BLUE="\[\033[0;34m\]"
    CHAR="✚"
    CHAR_COLOR="\\33"
    PS1="[\[\033[30;1m\]\t\[\033[0m\]]$RED$(parse_git_branch) \[\033[0;34m\]\W\[\033[0m\]\n\[\033[0;31m\]$CHAR \[\033[0m\]"
  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt force_color_prompt
}

init_direnv() {
  weHave direnv || return
  eval "$(direnv hook bash)"
}

init_fasfetch() {
  weHave fastfetch || return
  FASTFETCH_CONFIG="${DOTS_CFG}/fastfetch/config.jsonc"
  export FASTFETCH_CONFIG
  fastfetch --config "$FASTFETCH_CONFIG"
}

init_starship() {
  weHave starship || return
  STARSHIP_CONFIG="${DOTS_CFG}/starship/starship.toml"
  export STARSHIP_CONFIG
  set +o posix
  eval "$(starship init bash)"
  set -o posix
}

init_zoxide() {
  weHave zoxide || return
  # eval "$(zoxide init bash)"
  eval "$(zoxide init posix --hook prompt)"
}
