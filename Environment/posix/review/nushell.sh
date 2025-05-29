#!/bin/sh
# shellcheck disable=SC2154

case "$sys_INFO" in
*Linux*)
  NU_HOME="$DOTS_CLI/nushell"
  NU_LINK="$XDG_CONFIG_HOME/nushell"

  [ -L "$NU_LINK" ] ||
    if [ -d "$NU_HOME" ]; then
      #> Establish Link in BIN <#
      ln \
        --symbolic \
        --force \
        "$NU_HOME" \
        "$NU_LINK"
    else
      printf "🔴 NU_HOME != %s\n" "$NU_HOME"
    fi
  ;;
*) ;;
esac
