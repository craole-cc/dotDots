#!/bin/sh
# shellcheck disable=SC2154

case "$sys_INFO" in
*Linux*) ;;
*) exit 0 ;;
esac

YAMBAR_HOME="$DOTS_TOOL/widgets/yambar"
YAMBAR_CONF="$YAMBAR_HOME/config.yaml"

yambar_stop() { app_kill yambar;}
yambabr_start() { yambar --config="$YAMBAR_CONF"; }
Yam() {
  yambar_stop
  yambabr_start
}
