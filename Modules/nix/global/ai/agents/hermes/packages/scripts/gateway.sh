#!/bin/sh
#shellcheck enable=all
set -eu

export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
export HERMES_ENV_SH="${HERMES_ENV_SH:-@hermes_env_sh@}"

@prepare_hermes_gateway@
exec @hermes_exe@ gateway run "$@"
