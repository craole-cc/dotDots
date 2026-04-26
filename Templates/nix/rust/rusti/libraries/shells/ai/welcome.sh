#!/bin/sh

set -eu

header() {
  "$GUM" style \
    --border double \
    --border-foreground 212 \
    --align center \
    --width 68 \
    --margin "1 2" \
    --padding "1 2" \
    "AI Development Environment" \
    "Preset: $AI_PRESET"
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
  "mission-control list   Show available AI workflows" \
  "mc doctor              Show available AI tools" \
  "mc codex               Launch Codex if present" \
  "mc claude              Launch Claude Code if present"

section "Tooling" \
  "ai-command doctor      Print tool availability matrix" \
  "commands list          Show command shortcuts" \
  "mc usage               Launch ccusage if available"

section "Keys" \
  "OPENAI_API_KEY         Used by Codex and OpenAI tooling" \
  "ANTHROPIC_API_KEY      Used by Claude tooling" \
  "GEMINI_API_KEY         Used by Gemini tooling"
