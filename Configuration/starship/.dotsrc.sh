#!/bin/sh

#{ Set Environment Variables }
app="starship"
name="Starship Prompt"
# type="tty"
ext="toml"
theme="craole"
STARSHIP_HOME="${DOTS_CFG:?}/${app:?}" export STARSHIP_HOME
STARSHIP_CACHE="${CACHE_HOME:?}/${app:?}" export STARSHIP_CACHE
STARSHIP_CONFIG="${STARSHIP_HOME}/config.toml" export STARSHIP_CONFIG
STARSHIP_THEMES="${STARSHIP_HOME}/themes/" export STARSHIP_THEMES
STARSHIP_CONFIG="${STARSHIP_THEMES}/${theme}.${ext}"
if [ -f "${STARSHIP_CONFIG}" ]; then
  export STARSHIP_CONFIG
fi

#{ Verify installation }
if ! command -v starship >/dev/null 2>&1; then
  pout_tagged "[ERROR]" --ctx "${name}" \
    "Missing starship. Skipping..."
  return
fi

#{ Initialize }
#shellcheck disable=SC3040
case "${SHELL_TYPE:-"bash"}" in
zsh) eval "$(starship init zsh)" || true ;;
bash)
  set +o posix
  eval "$(starship init bash)" || true
  set -o posix
  ;;
*)
  pout_tagged "[ERROR]" --ctx "${name}" \
    "Unknown shell type: ${SHELL_TYPE}"
  exit 1
  ;;
esac

#{ Cleanup }
unset app ext theme
