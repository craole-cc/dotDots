#!/bin/sh
# shellcheck disable=SC2034,SC2154

FEND_HOME=$DOTS_TOOL/tools/fend
FEND_CONFIG_DIR="$FEND_HOME/config.toml"
FEND_STATE_DIR="$HOME/.local/state/fend/history"
FEND_CACHE_DIR="$HOME/.cache/fend"

CargoInstall fend