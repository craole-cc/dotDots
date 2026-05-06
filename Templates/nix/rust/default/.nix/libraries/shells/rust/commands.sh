#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: rust-command <command> [args...]

Commands:
  bench        Run cargo bench
  check        Run cargo check
  clippy       Run cargo clippy with warnings denied
  coverage     Generate tarpaulin HTML coverage output
  fmt          Format the project with cargo fmt and treefmt
  info         Show codebase stats and repository summary
  lint         Run treefmt, cargo fmt check, and clippy
  run          Run cargo run
  test         Run cargo nextest
  version      Show rustc version
  watch-check  Watch cargo check
  watch-run    Watch cargo run
  watch-test   Watch cargo nextest
EOF
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
bench)
  exec cargo bench "$@"
  ;;
check)
  exec cargo check "$@"
  ;;
clippy)
  exec cargo clippy --all-targets --all-features -- -D warnings
  ;;
coverage)
  exec cargo tarpaulin --out Html --output-dir coverage "$@"
  ;;
fmt)
  cargo fmt --all "$@"
  exec treefmt
  ;;
info)
  tokei
  exec onefetch
  ;;
lint)
  treefmt
  cargo fmt --all --check
  exec cargo clippy --all-targets --all-features -- -D warnings
  ;;
run)
  exec cargo run "$@"
  ;;
test)
  exec cargo nextest run "$@"
  ;;
version)
  exec rustc --version
  ;;
watch-check)
  exec cargo watch --quiet --clear --exec check "$@"
  ;;
watch-run)
  exec cargo watch --quiet --clear --exec run "$@"
  ;;
watch-test)
  exec cargo watch --quiet --clear --exec "nextest run" "$@"
  ;;
*)
  printf 'Unknown rust command: %s\n' "$cmd" >&2
  usage >&2
  exit 1
  ;;
esac
