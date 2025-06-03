#!/bin/sh

create_tmp_file() {
  app="${1:-fs}"
  dir="${2:-/tmp}"
  sec="$(date +%s)"
  uid="$(printf '%s.%s_%s' "${app}" "$$" "${sec}")"
  tmp_file="${dir}/${uid}"
  touch "${tmp_file}"
  printf '%s' "${tmp_file}"
}

y() {
  main() {
    cd_to_cwd "$@"
    cleanup
  }

  cleanup() {
    [ -n "${tmp_file}" ] && rm -f -- "${tmp_file}"
  }

  #{ Set up cleanup trap
  trap cleanup EXIT INT TERM HUP

  cd_to_cwd() {
    if command -v yazi; then
      tmp_file="$(create_tmp_file yazi-cwd)"
      yazi "$@" --cwd-file="${tmp_file}"
      if [ -f "${tmp_file}" ]; then
        #{ Read path preserving whitespace
        IFS= read -r cwd <"${tmp_file}"

        #{ If the cwd is a valid directory
        if [ -n "${cwd}" ] && [ -d "${cwd}" ]; then
          [ -n "${cwd}" ] && [ "${cwd}" != "${PWD}" ] && {
            # printf "Entering directory: %s\n" "${cwd}"
            builtin cd -- "${cwd}" || return 1
          }
        fi
      fi
    fi
  }

  main "$@"
}
