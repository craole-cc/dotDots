#!/bin/sh

if command -v fastfetch > /dev/null 2>&1; then
  fastfetch "$@"
else
  printf "Fastfetch doesn't seem to be available\n"
      return 1
fi
