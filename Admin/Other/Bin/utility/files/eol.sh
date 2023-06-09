#!/bin/sh
scr_PATH="$(PathOf "$0")"
scr_NAME="$(basename "$scr_PATH")"
scr_DIR="$(dirname "$scr_PATH")"
scr_VERSION="1.0"
scr_DEPENDENCIES="coreutils, perl, dos2unix & unix2dos"
scr_DESCRIPTION="converts between CRLF (DOS) and LF (*nix) text file formats"
scr_USAGE="Usage:
    $scr_NAME [OPTIONS] [VARIABLES]
"
scr_OPTIONS="Options:
    -h, --help             Show detailed help information
    -v, --version          Show the script version number
    -q, --quiet            Suppress all output including errors
    -d, --verbose <LEVEL>  Control level of information shared
    -c, --cr               Convert to CR line endings
    -l, --lf               Convert to LF line endings
"
scr_ARGUMENTS="Arguments:
    <LEVEL>    [quiet, info [default], debug, 0, 1, 2]
"
scr_EXAMPLES="Examples:
    $scr_NAME HOME XDG_CONFIG
    $scr_NAME HOME XDG_CONFIG --verbose info
    $scr_NAME -d=debug HOME
"
scr_AUTHORS="Authors:
    Craole <iamcraole@gmail.com>
"
scr_HELP="$(
  cat <<HELP
  $scr_NAME [v.$scr_VERSION] $scr_DESCRIPTION.

  $scr_USAGE
  $scr_OPTIONS
  $scr_ARGUMENTS
  $scr_EXAMPLES
  $scr_AUTHORS
HELP
)"

point_of_entry() {
  parse_arguments "$@"
}

convert_to_lf() {
  if dos2unix -h /dev/null 2>&1; then
    dos2unix "$1"
  elif perl -h /dev/null 2>&1; then
    perl -pi -e 's/\r\n$/\n/g' "$1"
  else
    sed -i 's/\r$//' "$1"
  fi
}

convert_to_cr() {
  if unix2dos -h /dev/null 2>&1; then
    unix2dos "$1"
  elif perl -h /dev/null 2>&1; then
    perl -pi -e 's/$/\r/' "$1"
  else
    sed -i 's/$/\r/' "$1"
  fi
}

parse_arguments() {
  #@ Ensure there is an argument to parse
  [ "$#" -eq 0 ] && {
    echo "we need something to process"
    exit 1
  }

  #@ Accept user options
  while [ "$#" -ge 1 ]; do
    case "$1" in
    -h | --help) present_info --exit "$scr_USAGE" ;;
    -v | --version) present_info --exit "$scr_VERSION" ;;
    -d | --verbose) verbose=true ;;
    -q | --quiet) unset verbose ;;
    -c | --cr) target_eol="cr" ;;
    -l | --lf) target_eol="lf" ;;
    esac
    shift
  done

  #@ If unset, set default eol based on Operating System
  [ "$target_eol" ] ||
    case $OS_TYPE in
    Windows) target_eol="cr" ;;
    *) target_eol="lf" ;;
    esac

  echo "$target_eol"
}

process_core() {
  files_processed=0
  table_header_printed=false

  while [ "$#" -ge 1 ]; do
    file="$1"
    if [ -f "$file" ]; then
      if [ "$table_header_printed" = false ]; then
        printf " | File | Conversion |\n"
        printf "|---|---|\n"
        table_header_printed=true
      fi

      case "$target_eol" in
      "cr")
        convert_to_cr "$file"
        printf "| $file | LF to CRLF |\n"
        ;;
      "lf")
        convert_to_lf "$file"
        printf "| $file | CRLF to LF |\n"
        ;;
      esac

      files_processed=$((files_processed + 1))
    else
      echo "File not found: $file"
    fi

    shift
  done

  printf "\nConversion of $files_processed file(s) completed.\n"
}

#@ __________________________________________________ INFO<|

__ver__() {
  echo "1.0"
}

__help__() {
  emojify "                      :spiral_notepad:  USAGE
        command <[options]> <[files]>
        >>> sortFile --row list.txt <<<
:arrow_forward: ----------------------------------------------- :arrow_backward:
    -h --help      Usage guide
    -L --lf        Line endings to LF
    -C --cr        Line endings to CR
"
}

display_info() { #@ Display information to via Stdout or Notification
  #? USAGE: display_info --noline $arg

  #@ Ensure there is something to print
  [ "$*" ] || return 1

  case "$1" in
  -l | -n | --new-line)
    shift
    printf '%s\n' "$*"
    ;;
  *) printf '%s' "$*" ;;
  esac
}

point_of_entry "$@"
