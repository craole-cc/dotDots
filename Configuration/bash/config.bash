#!/usr/bin/env bash

#~@ Only execute this script for interactive shells
case "${BASHOPTS}" in !*i*)
  if shopt -q login_shell; then
    exit
  else
    return
  fi
  ;;
*) ;; esac

#~@ Add the bin directory to the path
# PATH="$(pathman --append "$SHELL_HOME/bin" --print)" export PATH

#~@ Define a list of files to include
include_files=(
  "${SHELL_HOME}/modules"
  # "$SHELL_HOME/modules/**/*.bash"
)

#~@ Define a list of files to exclude
exclude_files=(
  "${SHELL_HOME}/scripts/rustup.bash"
  # "$SHELL_HOME/modules/exclude.bash"
)

#~@ Process the list of files to include
module_files=()
for file in "${include_files[@]}"; do
  found_files=$(find "${file}" -type f -not -path "${exclude_files[@]}")
  mapfile -t files < <(printf "%s\n" "${found_files}")
  module_files+=("${files[@]}")
done

#~@ Load modules
for module in "${module_files[@]}"; do
  if [[ -r "${module}" ]]; then
    init_time="$(date +%s%3N)"
    # shellcheck disable=SC1090
    source "${module}"
    exit_time="$(date +%s%3N)"
    pout_with_tag --tag "INFO " "$(
      printf "Module: %s (%sms)\n" \
        "$(basename "${module}")" \
        "$((exit_time - init_time))"
    )"
  else
    pout_with_tag --tag "WARN " "Module not readable:" "${module}"
  fi
done

init_prompt
# init_fasfetch

#~@ Clean up
unset module_files module
