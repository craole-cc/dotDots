#!/bin/sh

# _______________________________________ OPTIONS<|

# app=

__Usage() {
  echo "$0 usage:" &&
    grep "[[:space:]].)\ #" "$0" |
    sed 's/#//' |
      sed -r 's/([a-z])\)/-\1/'
  exit 0
}
__Help() {
  echo "Method --> Exists <APP>"
  echo "Usage:"
  echo "    pip -h                      Display this help message."
  echo "    pip install <package>       Install <package>."
  exit 0
}
__CheckMany() (
  for app in "$@"; do
    if command -v "$app" >/dev/null 2>&1; then
      Installed=true
      echo "$app" '→|' Found at "$(command -v "$app")"
    else
      unset Installed
      echo "$app" '→|' Not Found
    fi
  done
)
__Check() (
  app=$*
  if command -v "$app" >/dev/null 2>&1; then
    Installed=true
    echo "$app" '→|' Found at "$(command -v "$app")"
  else
    unset Installed
    echo "$app" '→|' Not Found
  fi
)
__Required() {
  __Check "$app"
  if ! $Installed; then
    echo Required '-->' "$app"
  else
    echo Installed '-->' "$app"
  fi
}

# __________________________________________ HELP<|

# __________________________________________ EXEC<|

[ $# -eq 0 ] &&
  Help
while getopts ":chsp:" arg; do
  case $arg in
  p)
    # Specify p value.
    echo "p is ${OPTARG}"
    ;;
  s)
    # Specify strength, either 45 or 90.
    strength=${OPTARG}
    [ "$strength" -eq 45 ] || [ "$strength" -eq 90 ] &&
      # [ $strength -eq 45 -o $strength -eq 90 ] &&
      echo "Strength is $strength." ||
      echo "Strength needs to be either 45 or 90, $strength found instead."
    ;;
  h)
    Help
    exit 0
    ;;
  c | *)
    appCheck
    echo "Check"
    exit 0
    ;;
  esac
done
