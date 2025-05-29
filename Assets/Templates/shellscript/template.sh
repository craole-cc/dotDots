#!/bin/sh
#shellcheck enable=all

main() {
  set_defaults
  pout pop --code 2 --debug felony
  # parse_arguments "$@"
  # validate_env
  # execute_process
}

set_defaults() {
  set -eu
  scr_path="$0" #TODO: This is not safe. Need to find a way to get the script path if the script is symlinked or sourced
  scr_name="$(basename "${scr_path}")"
  prj_root="${PRJ_ROOT:-${DOTS:="$(git rev-parse --show-toplevel 2> /dev/null || dirname "${scr_path}/..")"}}"
  delimiter=" "
  args=""

  #@ Define the pout command
  CMD_POUT="$(command -v pout 2> /dev/null || printf "")"
  [ "${CMD_POUT}" = "${scr_path:-$0}" ] && CMD_POUT=""
  CMD_POUT="${CMD_POUT:-"${prj_root}/Bin/shellscript/utility/output/pout"}"
}

pout() {
  #@ Use the pout command if it exists and is executable, otherwise use the default
  if [ -x "${CMD_POUT}" ]; then
    "${CMD_POUT}" "$@"
    return "$?"
  else
    #@ Show warning once if not previously shown
    if [ -z "${POUT_FALLBACK_WARNING_SHOWN:-}" ]; then
      printf "[WARN] /> %s <\ Using simplified pout(). Advanced options not fully supported.\n" "${scr_path}" >&2
      export POUT_FALLBACK_WARNING_SHOWN=1
    fi

    #@ Check for error/code flags
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --error | --warn | --fatal) use_stderr=1 ;;
        --code) code="$2" shift ;;
        *) msg="${msg:-}${msg:+${delimiter:- }}${1}" ;;
      esac
      shift
    done

    #@ Output the message to the appropriate console stream
    case "${use_stderr:-}" in
      1 | on | yes | true) printf "%s\n" "${msg:-}" >&2 ;;
      *) printf "%s\n" "${msg:-}" ;;
    esac

    #@ Return with the specified code
    return "${code:-0}"
  fi
}

pout_CONCISE() {
  CMD_POUT="$(command -v pout 2> /dev/null || printf "")"
  CMD_POUT="${CMD_POUT:-"${prj_root}/Bin/shellscript/utility/output/pout"}"

  if [ -x "${CMD_POUT}" ]; then
    "${CMD_POUT}" "$@"
    return "$?"
  else
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --code)
          shift
          code="$1"
          ;;
        *) msg="${msg:-}${msg:+${delimiter}}${1}" ;;
      esac
      shift
    done

    printf "%s\n" "${msg:-}"
    return "${code:-0}"
  fi
}

pout_VERBOSE() {
  #DOC Prints a formatted string to the console.
  #DOC
  #DOC Available options:
  #DOC   - `--line <N>`: Print `<N>` lines after the message.
  #DOC   - `--trim` or `--last <MSG>`: Print only the last line of `<MSG>`.
  #DOC   - `--upper <MSG>`: Print `<MSG>` in uppercase.
  #DOC   - `--lower <MSG>`: Print `<MSG>` in lowercase.
  #DOC   - `--alnum <MSG>` or `--clean <MSG>`: Remove non-alphanumeric characters from `<MSG>`.
  #DOC   - `--head <MSG>`: Print a formatted header with `<MSG>`.
  #DOC   - `--debug <MSG>`: Print a debug message with `<MSG>`.
  #DOC   - `--info <MSG>`: Print an informational message with `<MSG>`.
  #DOC   - `--warn <MSG>`: Print a warning message with `<MSG>`.
  #DOC   - `--error <MSG>`: Print an error message with `<MSG>`.
  #DOC   - `--fatal <MSG>`: Print a fatal error message and exit with code 1.
  #DOC   - `--exit <CODE> <MSG>`: Print an error message and exit with specified code.
  #DOC   - `--usage`: Print the usage guide.
  #DOC
  #DOC If no options are specified, the function will print the entire input string.

  # Initialize variables with safe defaults
  tag=""
  msg=""
  lines=1
  context="${scr_name:-unknown}"
  code=0
  delimiter=" "
  output_stream=1 # 1 for stdout, 2 for stderr

  # No arguments provided
  if [ $# -eq 0 ]; then
    pout --error "No arguments provided to pout function"
    return 1
  fi

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --context | --ctx)
        if [ $# -lt 2 ]; then
          pout --error "Missing argument for --context option"
          return 1
        fi
        shift
        context="$1"
        ;;
      --line)
        if [ $# -lt 2 ]; then
          pout --error "Missing argument for --line option"
          return 1
        fi
        shift
        if ! echo "$1" | grep -q '^[0-9]\+$'; then
          pout --error "Invalid number of lines: $1"
          return 1
        fi
        lines="$1"
        ;;
      --code)
        if [ $# -lt 2 ]; then
          pout --error "Missing argument for --code option"
          return 1
        fi
        shift
        if ! echo "$1" | grep -q '^[0-9]\+$'; then
          pout --error "Invalid code: $1"
          return 1
        fi
        code="$1"
        ;;
      --trim | --last)
        shift
        lines=0
        msg="$*"
        break
        ;;
      --upper)
        shift
        if [ $# -eq 0 ]; then
          pout --error "Missing argument for --upper option"
          return 1
        fi
        msg="$(printf "%s" "$*" | tr '[:lower:]' '[:upper:]')"
        break
        ;;
      --lower)
        shift
        if [ $# -eq 0 ]; then
          pout --error "Missing argument for --lower option"
          return 1
        fi
        msg="$(printf "%s" "$*" | tr '[:upper:]' '[:lower:]')"
        break
        ;;
      --alnum | --clean)
        shift
        if [ $# -eq 0 ]; then
          pout --error "Missing argument for --alnum/--clean option"
          return 1
        fi
        msg="$(printf "%s" "$*" | tr -cd '[:alnum:]_')"
        break
        ;;
      --head)
        shift
        if [ $# -eq 0 ]; then
          pout --error "Missing argument for --head option"
          return 1
        fi
        tag=""
        msg="===| $* |==="
        printf "\n"
        ;;
      --debug)
        shift
        case "${debug:-}" in
          '' | off | no | false | 0)
            # Skip debug messages if debug is disabled
            return 0
            ;;
          *)
            tag="[DEBUG]"
            output_stream=1
            if [ $# -eq 0 ]; then
              msg="Debug message (no content provided)"
            else
              msg="$*"
            fi
            break
            ;;
        esac
        ;;
      --info)
        shift
        tag="[INFO] "
        output_stream=1
        if [ $# -eq 0 ]; then
          msg="Info message (no content provided)"
        else
          msg="$*"
        fi
        break
        ;;
      --warn)
        shift
        tag="[WARN] "
        output_stream=2 # stderr
        if [ $# -eq 0 ]; then
          msg="Warning message (no content provided)"
        else
          msg="$*"
        fi
        break
        ;;
      --error)
        shift
        tag="[ERROR] "
        output_stream=2 # stderr
        if [ $# -eq 0 ]; then
          msg="Error occurred (no details provided)"
        else
          msg="$*"
        fi
        break
        ;;
      --fatal)
        shift
        tag="[FATAL] "
        output_stream=2 # stderr
        code=1
        if [ $# -eq 0 ]; then
          msg="Fatal error occurred (no details provided)"
        else
          msg="$*"
        fi
        break
        ;;
      --exit)
        if [ $# -lt 2 ]; then
          pout --error "Missing arguments for --exit option"
          return 1
        fi
        shift
        if ! echo "$1" | grep -q '^[0-9]\+$'; then
          pout --error "Invalid exit code: $1"
          return 1
        fi
        code="$1"
        shift
        tag="[ERROR] "
        output_stream=2 # stderr
        msg="$*"
        break
        ;;
      --usage)
        msg="$(usage_guide 2> /dev/null || echo "Usage guide not available")"
        ;;
      -*)
        pout --error "Unknown option: $1"
        return 1
        ;;
      *)
        # Handle regular message content
        if [ -z "$msg" ]; then
          msg="$1"
        else
          msg="${msg}${delimiter}${1}"
        fi
        ;;
    esac
    shift
  done

  # Ensure we have a message
  if [ -z "$msg" ] && [ -z "$tag" ]; then
    return 0 # Nothing to print
  fi

  # Format message with context if tag is present
  if [ -n "$tag" ]; then
    formatted_msg="$tag$msg"
    contextual_msg="$(printf "%s [%s] %s" "$tag" "$context" "$msg")"
  else
    formatted_msg="$msg"
    contextual_msg="$msg"
  fi

  # Print to appropriate stream
  if [ "$output_stream" -eq 2 ]; then
    printf "%s" "$formatted_msg" >&2
  else
    printf "%s" "$formatted_msg"
  fi

  # Print requested number of newlines
  _i=1
  while [ "$_i" -le "$lines" ]; do
    if [ "$output_stream" -eq 2 ]; then
      printf "\n" >&2
    else
      printf "\n"
    fi
    _i=$((_i + 1))
  done

  # Exit if required
  if [ "$code" -gt 0 ]; then
    exit "$code"
  fi

  return 0
}

pout_OLD() {
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
          '' | off | no | false) ;;
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

  #@ Update the tagged message
  [ -n "${tag}" ] \
    && msg="$(printf "%s /> %s <\ %s\n" "${tag}" "${scr_name}" "${msg}")"

  #@ Print to stdout or stderr
  case "${tag}" in
    *"ERR"* | *"WARN"*) printf "%s" "${msg}" >&2 ;;
    *) printf "%s" "${msg}" ;;
  esac

  #@ Terminate on errors
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

  [ -x "${CMD_NAME}" ] \
    || pout --error "Failed to locate dependency:" "${CMD_NAME}"
}

execute_process() {
  "${CMD_NAME}" "${args}"
}

main "$@"
