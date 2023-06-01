#!/bin/sh
# shellcheck disable=SC2034,SC2154

case "$sys_INFO" in
*Linux*)
  XMONAD_CONFIG_DIR="$DOTS_TOOL/interface/xmonad"
  XMONAD_DATA_DIR="$DATA_HOME/xmonad"
  XMONAD_CACHE_DIR="$CACHE_HOME/xmonad"

  [ -d "$XMONAD_CONFIG_DIR" ] ||
    printf "🔴 XMONAD_CONFIG_DIR != %s\n" "$XMONAD_CONFIG_DIR"
  ;;
*) ;;
esac
