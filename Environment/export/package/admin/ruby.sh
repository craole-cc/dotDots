#!/bin/sh
# shellcheck disable=SC2034,SC2154

#==================================================
# RUBY
#==================================================

# _________________________________ DOCUMENTATION<|


# _________________________________________ LOCAL<|

#* Verify Instalation *#
if ! type ruby >/dev/null 2>&1; then
  return
fi

GEM_HOME="$(ruby -e 'puts Gem.user_dir')/bin"
# PATH_add "$GEM_HOME"
# echo "$GEM_HOME"
# PATH="$PATH:$GEM_HOME"
# init_source --bin "$GEM_HOME"
  case ":${PATH}:" in
  *:"$GEM_HOME":*) ;;
  *)
    PATH="${PATH:+$PATH:}$GEM_HOME"
    [ "$verbose" ] && printf "Appended to PATH: %s\n" "${GEM_HOME}"
    ;;
  esac
