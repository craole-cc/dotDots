#!/bin/sh

if command -v eza >/dev/null 2>&1; then
  eza \
    --icons=always --group-directories-first --color=always \
    --color-scale \
    --all \
    --long \
    "$@"
elif command -v lsd >/dev/null 2>&1; then
  lsd \
    --color=always \
    --all \
    --human-readable \
    --group-directories-first \
    --long \
    "$@"
else
  ls -l \
    --color=always \
    --all \
    --human-readable \
    --group-directories-first \
    "$@"
fi
