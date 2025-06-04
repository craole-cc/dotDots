#!/bin/sh

init_rc "
  ${DOTS_ENV_POSIX_EXP:?}/base/admin
  ${DOTS_ENV_POSIX_EXP:?}/package/yazi.sh
  # ${DOTS_ENV_POSIX_EXP:?}/package/admin/review/ruby.sh
"
