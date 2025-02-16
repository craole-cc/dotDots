#!/usr/bin/env bash

MPD_CFG_DIR="${PWD}/config/MPD"
mkdir -p "$MPD_CFG_DIR/playlists"

#@ Run MPD with configs
# @mpd@/bin/mpd --config-dir="$MPD_CFG_DIR" "$@"
