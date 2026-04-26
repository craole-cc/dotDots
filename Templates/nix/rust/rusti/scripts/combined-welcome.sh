#!/bin/sh

set -eu

header() {
  "$GUM" style \
    --border double \
    --border-foreground 212 \
    --align center \
    --width 72 \
    --margin "1 2" \
    --padding "1 2" \
    "Combined Development Environment" \
    "Rust: $RUST_CHANNEL | AI: $AI_PRESET"
}

section() {
  title=$1
  shift

  "$GUM" style --foreground 212 --bold " $title"
  for line in "$@"; do
    "$GUM" style --foreground 250 "  $line"
  done
  printf '\n'
}

header

section "Mission Control" \
  "mission-control list   Show Rust and AI workflows" \
  "mc check               Run cargo check" \
  "mc test                Run cargo nextest" \
  "mc codex               Launch Codex when available" \
  "mc doctor              Show available AI tools"

section "Rust" \
  "rust-command fmt       Format with cargo fmt and treefmt" \
  "rust-command lint      Run treefmt, fmt check, and clippy" \
  "deploy-templates       Sync preferred template files"

section "AI" \
  "ai-command doctor      Print tool availability matrix" \
  "mc claude              Launch Claude Code when available" \
  "mc usage               Launch ccusage if available"

section "Context" \
  "Toolchain file: $RUST_TOOLCHAIN_FILE" \
  "Commands aliases: mc, commands"
