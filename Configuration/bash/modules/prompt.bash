#!/bin/sh

init_PS1() {
  # git dirty functions for prompt
  get_git_status() {
    git status --porcelain 2>/dev/null && echo "*"
  }

  # This function is called in your prompt to output your active git branch.
  get_git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
  }

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "${TERM}" in xterm-color | *-256color) color_prompt=yes ;; *) color_prompt= ;; esac

  if [[ -n "${force_color_prompt}" ]]; then
    if command -v tput >/dev/null && tput setaf 1 >/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
  fi

  if [[ "${color_prompt}" = yes ]]; then
    RED="\[\033[0;31m\]" # This syntax is some weird bash color thing I never
    # LIGHT_RED="\[\033[1;31m\]" # really understood
    # BLUE="\[\033[0;34m\]"
    CHAR="✚"
    # CHAR_COLOR="\\33"
    PS1="[\[\033[30;1m\]\t\[\033[0m\]]${RED}$(get_git_branch) \[\033[0;34m\]\W\[\033[0m\]\n\[\033[0;31m\]${CHAR} \[\033[0m\]"
  else
    [[ -n "${debian_chroot}" ]] && PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt force_color_prompt
}

init_direnv() {
  command -v direnv >/dev/null 2>&1 || return
  eval "$(direnv hook bash)" || true
}

init_fasfetch() {
  command -v fastfetch >/dev/null 2>&1 || return
  : "${FASTFETCH_CONFIG:=${DOTS_CFG}/fastfetch/config.jsonc}"
  export FASTFETCH_CONFIG
  fastfetch --config "${FASTFETCH_CONFIG}"
}

init_starship() {
  #@ Check if starship exists, return if not
  command -v starship >/dev/null 2>&1 || return

  #@ Set config path with POSIX-compliant parameter expansion
  : "${STARSHIP_CONFIG:=${DOTS_CFG}/starship/starship.toml}"
  export STARSHIP_CONFIG

  #@ Initialize starship (no POSIX mode toggling)
  eval "$(starship init bash)" || true
}

init_zoxide() {
  command -v zoxide >/dev/null 2>&1 || return
  # eval "$(zoxide init bash)" || true
  eval "$(zoxide init posix --hook prompt)" || true
}

init_thefuck() {
  command -v thefuck >/dev/null 2>&1 || return
  # shellcheck disable=SC2312
  eval "$(thefuck --alias)"
}

init_prompt() {
  #| Tools
  init_direnv
  init_zoxide
  init_thefuck

  #| Prompt
  init_starship
  status=$?
  if [[ "${status}" -ne 0 ]]; then
    init_PS1
  fi
}

init_prompt_with_fasfetch() {
  #| System Information
  init_fasfetch

  #| Prompt
  init_prompt
}
