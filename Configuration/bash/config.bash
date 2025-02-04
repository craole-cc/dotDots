#!/usr/bin/env bash

BDOTRC="$(realpath "${BASH_SOURCE[0]}")"
BDOTDIR="$(dirname "$BDOTRC")"
DOTS_CFG="${DOTS_CFG:-"$(dirname "$BDOTDIR")"}"
DOTS="${DOTS:-"$(dirname "$DOTS_CFG")"}"
DOTS_BIN="${DOTS_BIN:-"$DOTS/Utilities/bin"}"
export BDOTDIR BDOTRC DOTS DOTS_CFG DOTS_BIN

source_external_cfg() {
  [ -f /etc/bashrc ] && . /etc/bashrc
  [ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"
  [ -f "$HOME/.bash_functions" ] && . "$HOME/.bash_functions"
  [ -f "$HOME/.profile" ] && . "$HOME/.profile"
}

source_internal_cfg() {
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

  #@ Load resources and functions
  init_config "$BDOTDIR/functions"
  init_config "$BDOTDIR/resources"
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

source_external_cfg
source_internal_cfg
set_app_defaults
init_prompt
update_dots_path "$DOTS/Utilities/bin"
