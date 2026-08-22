#!/usr/bin/env bash

#{ Find the bash-completion file to source }
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  BASH_COMPLETION="/usr/share/bash-completion/bash_completion"
elif [[ -r /etc/bash_completion ]]; then
  BASH_COMPLETION="/etc/bash_completion"
fi

#{ Enable rustup completions, if necessary }
if rustup --version >/dev/null 2>&1; then
  rustup completions bash >"${SHELL_HOME:?}/scripts/rustup.bash"
fi

#{ Use bash-completion, if available
if ! shopt -oq posix; then
  # shellcheck disable=SC1090
  [[ -n ${PS1} ]] && [[ -f ${BASH_COMPLETION} ]] && . "${BASH_COMPLETION}"
fi
