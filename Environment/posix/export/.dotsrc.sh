#!/bin/sh

init_rc "
  #| Environment
  ${DOTS_ENV_POSIX_EXP:?}/admin.sh
  ${DOTS_ENV_POSIX_EXP:?}/history.sh
  ${DOTS_ENV_POSIX_EXP:?}/locale.sh

  #| Packages
  ${DOTS_ENV_POSIX_EXP:?}/yazi.sh
"
