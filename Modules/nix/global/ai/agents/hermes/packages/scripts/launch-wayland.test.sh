#!/bin/sh
# shellcheck shell=sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
launcher="$script_dir/launch-wayland.sh"
tools_file="$script_dir/../tools/default.nix"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  text="$1"
  expected="$2"
  printf '%s\n' "$text" | grep -F -- "$expected" >/dev/null \
    || fail "expected output to contain: $expected"
}

assert_file_contains() {
  file="$1"
  expected="$2"
  grep -F -- "$expected" "$file" >/dev/null \
    || fail "expected $file to contain: $expected"
}

# Both graphical command names must be wrappers; non-GUI tools remain direct.
assert_file_contains "$tools_file" 'writeShellScriptBin "hermes-desktop"'
assert_file_contains "$tools_file" 'writeShellScriptBin "hermes-one"'
assert_file_contains "$tools_file" 'launch-wayland.sh'

runtime_dir=$(mktemp -d)
socket_pids=""
cleanup() {
  for pid in $socket_pids; do
    kill "$pid" 2>/dev/null || true
  done
  rm -rf "$runtime_dir"
}
trap cleanup EXIT HUP INT TERM

start_socket() {
  socket_path="$1"
  python3 -c '
import os
import socket
import sys
import time

path = sys.argv[1]
sock = socket.socket(socket.AF_UNIX)
sock.bind(path)
try:
    time.sleep(30)
finally:
    sock.close()
    os.unlink(path)
' "$socket_path" &
  socket_pids="$socket_pids $!"

  attempts=0
  while [ ! -S "$socket_path" ]; do
    attempts=$((attempts + 1))
    [ "$attempts" -lt 100 ] || fail "socket was not created: $socket_path"
    sleep 0.01
  done
}

# A caller-selected display must not be replaced or inspected.
preserved=$(env -i PATH="$PATH" XDG_RUNTIME_DIR="$runtime_dir" WAYLAND_DISPLAY=caller-wayland "$launcher" /usr/bin/env)
assert_contains "$preserved" "XDG_RUNTIME_DIR=$runtime_dir"
assert_contains "$preserved" "WAYLAND_DISPLAY=caller-wayland"

# A single runtime-directory socket is selected by basename.
start_socket "$runtime_dir/wayland-test"
single=$(env -i PATH="$PATH" XDG_RUNTIME_DIR="$runtime_dir" "$launcher" /usr/bin/env)
assert_contains "$single" "XDG_RUNTIME_DIR=$runtime_dir"
assert_contains "$single" "WAYLAND_DISPLAY=wayland-test"

# An empty runtime directory fails rather than guessing a display.
missing_runtime=$(mktemp -d)
if missing_output=$(env -i PATH="$PATH" XDG_RUNTIME_DIR="$missing_runtime" "$launcher" /usr/bin/env 2>&1); then
  rm -rf "$missing_runtime"
  fail "missing socket invocation unexpectedly succeeded"
fi
rm -rf "$missing_runtime"
assert_contains "$missing_output" "no Wayland sockets"

# Multiple candidates fail rather than choosing an arbitrary display.
ambiguous_runtime=$(mktemp -d)
start_socket "$ambiguous_runtime/wayland-one"
start_socket "$ambiguous_runtime/wayland-two"
if ambiguous_output=$(env -i PATH="$PATH" XDG_RUNTIME_DIR="$ambiguous_runtime" "$launcher" /usr/bin/env 2>&1); then
  rm -rf "$ambiguous_runtime"
  fail "ambiguous socket invocation unexpectedly succeeded"
fi
rm -rf "$ambiguous_runtime"
assert_contains "$ambiguous_output" "multiple Wayland sockets"

printf 'PASS: launch-wayland environment handling\n'
