#!/bin/sh
#shellcheck enable=all

main() {
  set_defaults
  parse_arguments "$@"
  validate_env
  execute_process
}

set_defaults() {
  set -eu
  scr_path="$0"
  src_name="$(basename "${scr_path}")"
  prj_root="${PRJ_ROOT:-${DOTS:="$(dirname "${scr_path}/..")"}}"
  delimiter=" "
  args=""
  debug=0

  cmd_gyt_path="$(command -v gyt 2> /dev/null || printf '')"
  cmd_gyt_dots="${prj_root}/Bin/shellscript/project/git/gyt"
  [ -x "${cmd_gyt_dots}" ] || cmd_gyt_dots="${cmd_gyt_path}"
  CMD_GYT="${CMD_GYT:-"${cmd_gyt_dots:-}"}"
}

pout() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --error)
        shift
        tag="[ERROR]"
        msg="$*"
        code=1
        break
        ;;
      --debug)
        shift
        case "${debug:-}" in
          '' | 0 | off | no | false) ;;
          1 | on | true | *)
            tag="[DEBUG]"
            msg="$*"
            break
            ;;
        esac
        ;;
      --help)
        msg="HELP"
        break
        ;;
      *)
        msg="${msg}${msg:+${delimiter}}${1}"
        ;;
    esac
    shift
  done

  #{ Update the tagged message
  [ -n "${tag}" ] \
    && msg="$(printf "%s /> %s <\ %s\n" "${tag}" "${src_name}" "${msg}")"

  #{ Print to stdout or stderr
  case "${tag}" in
    *"ERR"* | *"WARN"*) printf "%s" "${msg}" >&2 ;;
    *) printf "%s" "${msg}" ;;
  esac

  #{ Terminate on errors
  [ "${code:-0}" -gt 0 ] && exit 1

}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h | --help | help | "/?")
        pout --help
        ;;
      -d | --debug | debug | dry-run | "/d")
        debug=1
        ;;
      *) args="${args}${args:+${delimiter}}${1}" ;;
    esac
    shift
  done
}

validate_env() {
  [ -d "${prj_root}" ] \
    || pout --error "Unable to determine the project root directory"

  [ -x "${CMD_GYT}" ] \
    || pout --error "Failed to locate dependency:" "${CMD_GYT}"
}

execute_process() {
  "${CMD_GYT}" "${args}"
}

main "$@"
