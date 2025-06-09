#!/bin/sh

if [ ! -d "${DOTS_ENV_POSIX_EXP:-}" ]; then return 0; else
  env_home="${DOTS_ENV_POSIX_EXP:-}"
fi

ordered_env="$(delim --out-delimiter "\n" "
  #| Environment
  ${env_home}/admin.sh
  ${env_home}/history.sh
  ${env_home}/locale.sh

  #| Packages
  ${env_home}/yazi.sh
")"

init_rc "${ordered_env}"
