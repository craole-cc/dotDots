#! /bin/sh

#==================================================
#
# NOTIFICATION TOOLKIT
# $SH_ENV/plugin_fm6000
#
#==================================================

# _________________________________ DOCUMENTATION<|

# __________________________________________ ECHO<|

# __________________________________________ TPUT<|
# TPUT() {
  set -a
  tp_red=$(tput setaf 1)
  tp_green=$(tput setaf 2)
  tp_blue=$(tput setaf 4)
  tp_magenta=$(tput setaf 5)
  tp_cyan=$(tput setaf 6)
  tp_reset=$(tput sgr0)
  set +a
# }
# __________________________________________ ECHO<|

# --> Fix ECHO deficiencies
# https://www.etalabs.net/sh_tricks.html

# Approach 2
echo() {
  fmt=%s end=\\n IFS=" "

  while [ $# -gt 1 ]; do
    case "$1" in
    [!-]* | -*[!ne]*) break ;;
    *ne* | *en*) fmt=%b end= ;;
    *n*) end= ;;
    *e*) fmt=%b ;;
    esac
    shift
  done

  printf "$fmt$end" "$*"
}

# Approach 2
note() { printf %s\\n "$*"; }

# ___________________________________________ ECO<|

eco() { printf %s\\n "$*"; }

# ___________________________________________ SAY<|

say() {
  msg=$*
  echo "$msg"
  notify-send "$msg"
}

# _________________________________________ ALIAS<|

alias echo="say"

Tester() {
  echo "work nuh"
}
