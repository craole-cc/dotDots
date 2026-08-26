#!/bin/sh
# shellcheck shell=sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
env_sh="$script_dir/env.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# A dangling .env symlink must fail closed without materializing its target.
mkdir -m 700 "$fixture/home"
dangling_target="$fixture/external-target"
ln -s "$dangling_target" "$fixture/home/.env"
if HERMES_HOME="$fixture/home" HERMES_ENV_PY=/bin/false sh -c '. "$1"' sh "$env_sh"; then
  fail 'dangling .env symlink unexpectedly succeeded'
fi
[ ! -e "$dangling_target" ] || fail 'dangling .env symlink materialized its target'

# A symlink to an existing foreign-owned path must also fail before mutation.
ln -s /etc/passwd "$fixture/home/.env-existing"
mv "$fixture/home/.env-existing" "$fixture/home/.env"
if HERMES_HOME="$fixture/home" HERMES_ENV_PY=/bin/false sh -c '. "$1"' sh "$env_sh"; then
  fail 'existing .env symlink unexpectedly succeeded'
fi

printf '%s\n' 'PASS: Hermes environment file safety'
