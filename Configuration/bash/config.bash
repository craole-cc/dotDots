#!/usr/bin/env bash

BDOTRC="$(realpath "${BASH_SOURCE[0]}")"
BDOTDIR="$(dirname "$BDOTRC")"
export BDOTRC BDOTDIR

DOTS="$HOME/.dots"
DOTS_BIN="$DOTS/Bin"
DOTS_CFG="$DOTS/Configuration"
export DOTS DOTS_BIN DOTS_CFG

init_config() {
  conf_files="$(find "$1" -type f)"

  for conf in $conf_files; do
    if [ -r "$conf" ]; then
      # time . "$conf"
      . "$conf"
    else
      printf "File not readable:  %s" "$conf"
    fi
  done
}

set_app_defaults() {

  #| Default TTY Editor
  if weHave hx; then
    EDITOR="hx"
  elif weHave nvim; then
    EDITOR="nvim"
  elif weHave nano; then
    EDITOR="nano"
  else
    EDITOR="vi"
  fi
  export EDITOR

  #| Default GUI Editor
  if weHave code; then
    VISUAL="code"
  elif weHave code-insiders; then
    VISUAL="code-insiders"
  elif weHave codium; then
    VISUAL="codium"
  elif weHave zeditor; then
    VISUAL="zeditor"
  else
    VISUAL="$EDITOR"
  fi
  export VISUAL

  #| Default TTY Reader/Pager
  if weHave bat; then
    READER="bat"
  elif weHave most; then
    READER="most"
  elif weHave less; then
    READER="less"
  elif weHave more; then
    READER="more"
  else
    READER="cat"
  fi
  export READER
}

#@ Only execute this script for interactive shells
case "$BASHOPTS" in
*i*)
  #@ Source the system-wide profile if SSH client is detected
  [ -n "$SSH_CLIENT" ] && . /etc/profile
  [ -f /etc/bashrc ] && . /etc/bashrc
  [ -f ~/.bash_aliases ] && . ~/.bash_aliases
  [ -f ~/.bash_profile ] && . ~/.bash_profile
  [ -f ~/.bash_login ] && . ~/.bash_login
  [ -f ~/.bash_functions ] && . ~/.bash_functions
  [ -f ~/.profile ] && . ~/.profile

  FASTFETCH_CONFIG="$DOTS_CFG/fastfetch/config.jsonc"
  STARSHIP_CONFIG="$DOTS_CFG/starship/config.toml"

  TREEFMT_CONFIG="$DOTS_CFG/treefmt/config.toml"
  alias treefmt='treefmt --config "$TREEFMT_CONFIG"'

  #@ Load resources and functions
  init_config "$BDOTDIR/functions"
  init_config "$BDOTDIR/resources"

  update_dots_path "$DOTS/Bin"
  set_app_defaults
  init_prompt
  ;;
*)
  # If this is a login shell, exit instead of returning
  # to ensure that the shell is completely closed.
  if shopt -q login_shell; then
    exit
  else
    return
  fi
  ;;
esac
