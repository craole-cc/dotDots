#!/bin/sh

[ "$#" -ge 1 ] || {
  printf "No arguments provided\n"
  exit 1
}

_args=""
_lint=""

while [ "$#" -ge 1 ]; do
  case "$1" in
  --lint | --check) _lint=true ;;
  *) _args="${_args:+$_args }$1" ;;
  esac
  shift
done

for _file in $_args; do
  if [ "$_lint" ]; then
    sed -E \
      -e "s/^([[:blank:]]*)([a-zA-Z_]+[[:blank:]]*=)/  \\2/" \
      -e "s/[[:blank:]]+$//" "$_file" |
      diff "$_file" - >/dev/null || {
      printf "Formatting needed for: %s\n" "$_file"
      format_needed=true
      continue
    }
  else
    sed -E \
      -e "s/^([[:blank:]]*)([a-zA-Z_]+[[:blank:]]*=)/  \\2/" \
      -e "s/[[:blank:]]+$//" "$_file" |
      diff "$_file" - >/dev/null
    continue
  fi
done

[ "$format_needed" ] && exit 1
exit 0
