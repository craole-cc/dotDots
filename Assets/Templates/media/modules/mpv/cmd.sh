#!/bin/sh

MPV_CFG_DIR="${PWD}/config/mpv"
mkdir -p "${MPV_CFG_DIR}/scripts"

#@ Copy the ytdl_hook script if it doesn't exist

if [ ! -f "${MPV_CFG_DIR}/scripts/ytdl_hook.lua" ]; then
  cp "@mpv@/share/mpv/scripts/ytdl_hook.lua" "${MPV_CFG_DIR}/scripts/"
fi

#@ Run the command with options
@mpv@/bin/mpv --config-dir="${MPV_CFG_DIR}" "$@"
