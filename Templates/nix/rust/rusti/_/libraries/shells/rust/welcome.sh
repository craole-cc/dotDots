#!/bin/sh

set -eu

header() {
  "${CMD_GUM}" style \
    --border double \
    --border-foreground 212 \
    --align center \
    --width 68 \
    --margin "1 2" \
    --padding "1 2" \
    "Rust Development Environment" \
    "Channel: $RUST_CHANNEL | Version: $(rustc --version | cut -d ' ' -f2)"
}

section() {
  title=$1
  shift

  "${CMD_GUM}" style --foreground 212 --bold " $title"
  for line in "$@"; do
    "${CMD_GUM}" style --foreground 250 "  $line"
  done
  printf '\n'
}

header

section "Mission Control" \
  "mission-control list   Show available workflow commands" \
  "mc check               Run cargo check" \
  "mc test                Run cargo nextest" \
  "mc deploy --force      Reinstall template files"

section "Project Shortcuts" \
  "rust-command fmt       Format with cargo fmt and treefmt" \
  "rust-command lint      Run treefmt, fmt check, and clippy" \
  "rust-command watch-run Watch cargo run" \
  "reset-flake            Remove deployed templates and temp dirs"

section "Templates" \
  "Templates deploy automatically on shell entry" \
  "deploy-templates       Sync preferred template files" \
  "deploy-templates -f    Overwrite local template changes"

section "Context" \
  "Toolchain file: ${RUST_TOOLCHAIN_FILE:-"n/a"}" \
  "Commands alias: commands list"
