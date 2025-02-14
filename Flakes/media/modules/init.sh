#!/bin/sh

#@ Set up executable scripts
chmod +x bin/*
PATH="$PATH:$PWD/bin"
export PATH

#@ Set up aliases
alias radio='curseradio'

#@ Print usage message
printf "Video Tools:\n"
printf "  mpv      - Enhanced MPV with custom config\n"
printf "  ytd      - Download videos (usage: ytd <url> [quality])\n\n"

printf "Image Viewers:\n"
printf "  feh      - Light image viewer\n"
printf "  imv      - Alternative image viewer\n\n"

printf "Music & Radio:\n"
printf "  ncmpcpp  - Music player (music dir: music)\n"
printf "  radio    - Terminal radio\n\n"
