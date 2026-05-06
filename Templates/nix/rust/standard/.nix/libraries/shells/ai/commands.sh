#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ai-command <command> [args...]

Commands:
  agents    Run agentsview if available
  claude    Run claude-code if available
  codex     Run codex if available
  doctor    Show which AI tools are available on PATH
  gemini    Run gemini-cli if available
  goose     Run goose-cli if available
  opencode  Run opencode if available
  usage     Run ccusage if available
EOF
}

run_tool() {
  while [ "$#" -gt 0 ]; do
    tool=$1
    shift

    if [ "$tool" = "--" ]; then
      break
    fi

    if command -v "$tool" >/dev/null 2>&1; then
      exec "$tool" "$@"
    fi
  done

  printf 'Requested AI tool is not available in this shell.\n' >&2
  exit 1
}

doctor() {
  for tool in codex claude-code claude gemini gemini-cli goose-cli goose opencode ccusage agentsview; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf 'available %s\n' "$tool"
    else
      printf 'missing %s\n' "$tool"
    fi
  done
}

cmd=${1:-}

if [ -z "$cmd" ]; then
  usage
  exit 0
fi

shift

case "$cmd" in
help | list | ls)
  usage
  ;;
agents)
  run_tool agentsview -- "$@"
  ;;
claude)
  run_tool claude-code claude -- "$@"
  ;;
codex)
  run_tool codex -- "$@"
  ;;
doctor)
  doctor
  ;;
gemini)
  run_tool gemini gemini-cli -- "$@"
  ;;
goose)
  run_tool goose-cli goose -- "$@"
  ;;
opencode)
  run_tool opencode -- "$@"
  ;;
usage)
  run_tool ccusage -- "$@"
  ;;
*)
  printf 'Unknown AI command: %s\n' "$cmd" >&2
  usage >&2
  exit 1
  ;;
esac
