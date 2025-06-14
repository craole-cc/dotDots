#! /bin/sh

#==================================================
#
# STARSHIP
# CLI/bin/environment/app/starship.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

#@ Verify Installation
command -v starship >/dev/null 2>&1 || return

#@ Set Environment Variables
STARSHIP_HOME="${DOTS_CFG:?}/starship"
STARSHIP_CACHE="${CACHE_HOME:?}/starship"
STARSHIP_CONFIG="${STARSHIP_HOME}/config.toml"

#> THEME
: <<THEMES
  bracketed-segments
  default
  craole
  nerd-font-symbols
  no-nerd-font
  pastel-powerline
  tokyo-night
THEMES
starship_theme="${starship_theme:-craole}"
STARSHIP_THEME="${STARSHIP_HOME}/themes/${starship_theme}.toml"

#{ Update the theme }
if [ -f "${STARSHIP_THEME}" ]; then
  cmp -s "${STARSHIP_THEME}" "${STARSHIP_CONFIG}" ||
    symbiolink --force \
      --src "${STARSHIP_THEME}" \
      --lnk "${STARSHIP_CONFIG}"
else
  printf "Invalid Starship Theme: %s\n" "${STARSHIP_THEME}"
fi

# case "${SHELL_TYPE}" in
# *fish) ;;
# *nu) ;;
# *zsh) ;;
# *bash)
#   set +o posix
#   eval "$(starship init bash)"
#   set -o posix
#   ;;
# esac
