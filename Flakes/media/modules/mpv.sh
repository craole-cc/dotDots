#!/usr/bin/env bash

CFG_DIR="${PWD}/config/mpv"
mkdir -p "$CFG_DIR/scripts"

#@ Copy the ytdl_hook script if it doesn't exist
if [ ! -f "$CFG_DIR/scripts/ytdl_hook.lua" ]; then
  cp "@mpv@/share/mpv/scripts/ytdl_hook.lua" "$CFG_DIR/scripts/"
fi

#@ Run MPV with configs
@mpv@/bin/mpv --config-dir="$CFG_DIR" "$@"
