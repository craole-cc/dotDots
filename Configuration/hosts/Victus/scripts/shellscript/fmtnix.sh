#!/bin/sh

fd --full-path "${1:-$PWD}" --extension "nix" --exec-batch nixfmt
