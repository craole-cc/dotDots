#!/bin/sh
scr_path="${HOME}/.profile"

main() {
  : "${VERBOSITY:="info"}"
  : "${DELIMITER:="$(printf "\037")"}"
  : "${RC:=".dotsrc"}"
  : "${EDITOR:=hx}"
  : "${pad:=12}"
  : "${sep:=" | "}"
  manage_env --var HOME --val "${HOME:-}" --force
  manage_env --var BASH_RC --val "${HOME}/.bashrc" --force
  manage_env --var PROFILE --val "${HOME}/.profile" --force
  register_dots "${@:-}"
}

register_dots() {
  #DOC Finds and defines DOTS and DOTS_RC variables.
  #DOC
  #DOC Description:
  #DOC   This function searches for the configuration file named by the global
  #DOC   variable "RC" (".dotsrc" by default) in the directories specified by the
  #DOC   global variable "homes" and "names".  If found, it exports the directory
  #DOC   containing the file as "DOTS", the full path to the file as "DOTS_RC",
  #DOC   and the name of the file as "RC".  It then sources the file.
  #DOC
  #DOC  Arguments:
  #DOC    rc      - The name of the file to search for (default: ".dotsrc")
  #DOC    homes   - A colon-separated list of directories to search
  #DOC    names   - A colon-separated list of directory names to search
  #DOC
  #DOC  Returns:
  #DOC    0       - If the configuration file is found and sourced successfully
  #DOC    1       - If the configuration file is not found
  #DOC
  #DOC  Exports:
  #DOC    DOTS      - The directory containing the configuration file
  #DOC    DOTS_RC   - The full path to the configuration file
  #DOC    RC        - The name of the configuration file
  #DOC
  #DOC  Example:
  #DOC   register_dots \
  #DOC      --name "dotfiles" \
  #DOC      --home "/d/Projects/GitHub/CC" \
  #DOC      --home "/cygdrive/d/Projects/GitHub/CC" \
  #DOC      --name ".dots"
  #DOC    cd_DOTS
  #DOC    EDITOR=hx ed_DOTS_RC

  main() {
    trap 'cleanup' EXIT HUP INT TERM
    set_defaults
    parse_arguments "$@"
    execute_process
  }

  set_defaults() {
    #DOC Initializes default configuration values for the script.
    #DOC
    #DOC - Sets the function name to "register_dots".
    #DOC - Configures the DELIMITER used for separating values in lists.
    #DOC - Preserves the original IFS (Internal Field Separator) and sets a custom
    #DOC - Defines the default verbosity level as "info".
    #DOC - Sets the default configuration file name to ".dotsrc" if not already defined.
    #DOC - Establishes potential home directories and directory names for searching.

    #DOC Restore shell state to pre-function invocation.
    cleanup() {
      IFS="${ifs}"
      unset names homes ctx fn_name rc
    } && cleanup

    #~@ Initialize integral variables
    : "${fn_name:="register_dots"}"
    : "${RC:=".dotsrc"}"
    : "${EDITOR:=hx}"
    : "${DELIMITER:="$(printf "\037")"}"
    : "${VERBOSITY:="INFO"}"
    : "${possible_homes:="$(
      printf '%s\n' \
        "/d/Projects/GitHub/CC" \
        "/cygdrive/d/Projects/GitHub/CC" \
        "/d/Configuration" \
        "/cygdrive/d/Configuration" \
        "/shared/Dotfiles" \
        "/cygdrive/d/Dotfiles" \
        "${HOME}"
    )"}"
    : "${possible_names:="$(
      printf '%s\n' \
        ".dots" \
        "dotDots" \
        "dots" \
        "dotfiles" \
        "global" \
        "config" \
        "common"
    )"}"
    : "${ifs:="${IFS}"}"
  }

  parse_arguments() {
    #DOC Parse command-line arguments to set configuration options.
    #DOC
    #DOC Recognized options:
    #DOC -h, --help            Display usage information and exit.
    #DOC -d, --debug, --dry-run
    #DOC                      Enable debug verbosity level.
    #DOC --name, --dir DIRNAME
    #DOC                      Add DIRNAME to the list of directory names.
    #DOC --home, --parent DIR Add DIR to the list of parent directories.
    #DOC --rc RCFILE          Specify the basename of the RC file to look for.
    #DOC
    #DOC Arguments without options are added to the list of parent directories.
    #DOC Returns 0 on success, 1 on errors such as missing arguments.

    #~@ Set defaults
    homes="" names=""

    #~@ Parse Arguments
    while [ $# -gt 0 ]; do
      case "$1" in
      -h | --help)
        printf 'Usage: %s [--name DIRNAME] [--home DIR] [-d|--debug]\n' "${scr_path}/${fn_name}"
        return 0
        ;;
      -d | --debug | --dry-run)
        VERBOSITY="DEBUG"
        ;;
      --name | --dir)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        names="${names:+${names}${DELIMITER}}$2"
        shift
        ;;
      --home | --parent)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        homes="${homes:+${homes}${DELIMITER}}$2"
        shift
        ;;
      --rc)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        RC="$2"
        shift
        ;;
      *)
        homes="${homes:+${homes}${DELIMITER}}$1"
        ;;
      esac
      shift
    done

    #~@ Declare constants at the global level
    export DELIMITER RC VERBOSITY EDITOR
  }

  execute_process() {
    #DOC Locate the first of the specified directories that contain a ".dotsrc" at the top level
    #DOC
    #DOC @param {string} [rc=".dotsrc"] The filename of the file to search for
    #DOC @param {string} [homes] A colon-separated list of directories to search
    #DOC @param {string} [names] A colon-separated list of directory names to search
    #DOC
    #DOC @returns {none} Sets the global variables "DOTS", "DOTS_RC" and "RC"

    #~@ Set defaults
    homes="$(
      printf "%s\n" "${homes:-"${possible_homes}"}" |
        tr '\n' "${DELIMITER}"
    )"
    names="$(
      printf "%s\n" "${names:-"${possible_names}"}" |
        tr '\n' "${DELIMITER}"
    )"
    p=0

    #~@ Loop through the specified parent directories
    ifs="${IFS}"
    IFS="${DELIMITER}"
    for parent in ${homes}; do
      [ -d "${parent}" ] || continue
      p="$((p + 1))"

      #~@ Loop through the specified directory names appended to the parent
      d=0
      for dir in ${names}; do
        dots="${parent}/${dir}"
        [ -d "${dots}" ] || continue
        d="$((d + 1))"

        #~@ Use find to locate the first ".dotsrc" in the specified directory
        DOTS_RC=$(
          find "${dots}" \
            -maxdepth 1 \
            -type f -name "${RC}" \
            -print -quit
        )
        if [ -f "${DOTS_RC:-}" ]; then
          DOTS="$(dirname "${DOTS_RC:-}")"
          RC="$(basename "${DOTS_RC:-}")"
          break 2
        fi

      done
    done
    IFS="${ifs}"

    if [ -f "${DOTS_RC:-}" ]; then
      manage_env --force --var DOTS --val "${DOTS:?}" --init
      manage_env --force --var DOTS_RC --val "${DOTS_RC:?}"
    else
      return 1
    fi
  }

  main "$@"
}

manage_env() {
  main() {
    trap 'cleanup' EXIT HUP INT TERM
    set_defaults
    parse_arguments "$@"
    execute_process
  }

  cleanup() {
    unset action actions var val force init args
  }

  set_defaults() {
    cleanup
    fn_name="manage_env"
    tag=">>= ${fn_name} =<<"
    action="register"
    actions="edit | env | init | initialize | resolve | register | set | unregister | unset"
    var="" val="" args=""
    : "${RC:=.dotsrc}"
    : "${EDITOR:=hx}"
  }

  parse_arguments() {
    while [ $# -ge 1 ]; do
      case "$1" in
      --help | -h)
        show_usage
        return 0
        ;;
      -[dD] | --debug | --verbose | -V) verbosity=4 ;;
      -[fD] | -[yY] | --force | --yes) force=true ;;
      -[iI] | --init | --initialize) action="init" ;;
      -R | --register | --set | -s) action="register" ;;
      -U | --unregister | -unset | -u) action="unregister" ;;
      -r | --resolve) action="resolve" ;;
      -e | --edit) action="edit" ;;
      -a | --action)
        if [ "$#" -gt 1 ]; then
          shift
          if printf "%s" "${actions}" | grep -q "^${1}$"; then
            action=$1
          else
            show_usage action
            return 1
          fi
        else
          show_usage "$1"
          return 1
        fi
        ;;
      -E | --editor)
        if [ "$#" -gt 1 ]; then
          shift
          EDITOR="$1"
        else
          show_usage "$1"
          return 1
        fi
        ;;
      --rc | --target)
        if [ "$#" -gt 1 ]; then
          shift
          RC="$1"
        else
          show_usage "$1"
          return 1
        fi
        ;;
      -k | --key | --var)
        if [ "$#" -gt 1 ]; then
          shift
          var="$1"
        else
          show_usage "$1"
          return 1
        fi
        ;;
      -p | --path | --val)
        if [ "$#" -gt 1 ]; then
          shift
          val="$1"
        else
          show_usage "$1"
          return 1
        fi
        ;;
      *)
        args="${args:+${args}${DELIMITER}}$1"
        ;;
      esac
      shift
    done

    #~@ Parse positional arguments, if necessary
    ifs="${IFS}"
    IFS="${DELIMITER}"
    # shellcheck disable=SC2086
    set -- ${args}
    IFS="${ifs}"
    [ -z "${var:-}" ] && {
      var=$1
      shift
    }
    [ -z "${val:-}" ] && val=$*

    #~@ Validate arguments
    if [ -z "${var:-}" ] || [ -z "${val:-}" ]; then
      show_usage arguments
      return 1
    fi

    #~@ Print debug information
    verbosity="$(get_verbosity "${verbosity}")"
    if [ "${verbosity:-0}" -ge 4 ]; then
      pout_tagged --ctx manage_env --tag DEBUG --msg "$(
        printf "\n  %${pad}s%s%s" " ACTION" "${sep}" "${action}"
        printf "\n  %${pad}s%s%s" "ENV_var" "${sep}" "${var}"
        printf "\n  %${pad}s%s%s" "ENV_val" "${sep}" "${val}"
        printf "\n  %${pad}s%s%s" "EDITOR" "${sep}" "${EDITOR}"
        printf "\n  %${pad}s%s%s" "    RC" "${sep}" "${RC}"
        printf "\n  %${pad}s%s%s" " FORCE" "${sep}" "${force}"
        printf "\n  %${pad}s%s%s" "  INIT" "${sep}" "${init}"
      )"
    fi
  }

  execute_process() {
    case "${action:-}" in
    init | initialize | register | set)
      case "${action:-}" in init) init="--init" ;; *) ;; esac
      case "${force:-}" in 1 | true | yes | on) force="--force" ;; *) ;; esac
      register_env "${force}" "${init}" --var "${var}" --val "${val}"
      ;;
    unregister | unset) unregister_env "${var}" ;;
    edit) edit "${var}" ;;
    resolve | env) resolve_env "${var}" ;;
    *)
      show_usage action
      return 1
      ;;
    esac

    #~@ Return the result of the last command
    return $?
  }

  show_usage() {
    tag="ERROR ${tag}"

    case "$1" in
    action)
      printf '%s Action must be one of: %s\n' "${tag}" "${actions}"
      show_usage
      ;;
    -k | --key | --var | -p | --path | --val | -a | --action | -E | --editor | --rc | --target)
      printf '%s Missing argument for '%s'\n' "${tag}" "$1"
      show_usage
      ;;
    arguments | *)
      printf 'Usage: %s [--action ACTION] [--rc RC] [--editor EDITOR] [--key KEY] [--path PATH]\n' "${fn_name}"
      printf '\n'
      printf 'Options:\n'
      printf '  -h, --help            Display usage information and exit.\n'
      printf '  -R, --register, --set, -s\n'
      printf '                        Register the specified key and path.\n'
      printf '  -U, --unregister, -unset, -u\n'
      printf '                       Unregister the specified key.\n'
      printf ' -c, --check, --validate\n'
      printf '                       Check if the specified path exists.\n'
      printf ' -r, --resolve\n'
      printf '                       Resolve the specified path.\n'
      printf ' -e, --edit\n'
      printf '                       Edit the specified path.\n'
      printf ' -a, --action ACTION\n'
      printf '                       Specify the action to perform.\n'
      printf ' -E, --editor EDITOR\n'
      printf '                       Specify the editor to use.\n'
      printf ' --rc RC\n'
      printf '                       Specify the RC file to use.\n'
      printf ' -k, --key, --var KEY\n'
      printf '                       Specify the key to register.\n'
      printf ' -p, --path, --val PATH\n'
      printf '                       Specify the path to register.\n'
      ;;
    esac
  }

  main "$@"
}

register_env() {
  #~@ Set defaults
  _val="" _var="" _env="" _args="" _init=0 _force=0
  action="resolve"
  actions="edit | env | init | initialize | resolve | register | set | unregister | unset"
  : "${RC:=.dotsrc}"
  : "${EDITOR:=hx}"
  : "${RC:=.dotsrc}"
  : "${EDITOR:=hx}"

  #~@ Parse arguments
  while [ $# -ge 1 ]; do
    case "$1" in
    -[iI] | --init | --initialize) _init=1 ;;
    -[fF] | --force) _force=1 ;;
    --var)
      _var="$2"
      shift
      ;;
    --val)
      _val="$2"
      shift
      ;;
    --)
      #~@ End of options, everything after is positional
      shift
      break
      ;;
    -*)
      #~@ Unknown option, skip
      ;;
    *)
      #~@ Positional argument
      _args="${_args:+${_args}${DELIMITER}}$1"
      ;;
    esac
    shift
  done

  #~@ Handle remaining arguments after -- separator
  while [ $# -ge 1 ]; do
    _args="${_args:+${_args}${DELIMITER}}$1"
    shift
  done

  #~@ Parse positional arguments, if necessary
  if [ -n "${_args}" ]; then
    ifs="${IFS}"
    IFS="${DELIMITER}"
    # shellcheck disable=SC2086
    set -- ${_args}
    IFS="${ifs}"

    [ -z "${_var:-}" ] && {
      _var="$1"
      shift
    }
    [ -z "${_val:-}" ] && _val="$*"
  fi

  #~@ Validate arguments
  if [ -z "${_var:-}" ] || [ -z "${_val:-}" ]; then
    show_usage arguments
    return 1
  fi

  #~@ Print debug information
  if [ "${verbosity:-0}" -ge 4 ]; then
    pout_tagged --ctx register_env --msg "$(
      printf "\n  %${pad}s%s%s" "INIT" "${sep}" "${_init}"
      printf "\n  %${pad}s%s%s" "FORCE" "${sep}" "${_force}"
      printf "\n  %${pad}s%s%s" " VAR" "${sep}" "${_var}"
      printf "\n  %${pad}s%s%s" " VAL" "${sep}" "${_val}"
    )"
  fi

  #~@ Check the value of the variable
  var_val=""
  var_val="$(resolve_env "${_var}")"
  case "${var_val:-}" in
  "")
    #? Variable doesn't exist in system, use argument value
    ;;
  "${_val}")
    #? System value matches argument value - no change needed
    ;;
  *)
    #? System value differs from argument value
    if [ "${_force}" -eq 1 ]; then
      #~@ Force overwrite - use argument value without prompting
      if [ "${verbosity:-0}" -ge 2 ]; then
        pout_tagged --ctx register_env --tag "WARN " --msg "$(
          printf "Forcing overwrite of %s: %s -> %s\n" "${_var}" "${var_val}" "${_val}"
        )"
      fi
    else
      #~@ Offer the option to overwrite
      printf "%s is already set to: %s\nNew value would be: %s\n%s" \
        "${_var}" "${var_val}" "${_val}" \
        "Overwrite? [y/N] (default: N): "

      #~@ Set a trap for CTRL-C during read
      trap 'echo "\nCancelled by user"; _val="${var_val}"; trap - INT' INT
      read -r response
      trap - INT #? Clear trap after read

      #~@ Handle the user response
      case "${response}" in
      [Yy]*)
        #~@ Update the env to the argument value
        ;;
      *)
        #~@ Keep the existing system value
        _val="${var_val}"
        ;;
      esac
    fi
    ;;
  esac

  #~@ Register the variable globally
  eval "${_var}=\"\${_val}\""
  eval "export ${_var}"

  if [ "${verbosity:-0}" -ge 4 ]; then
    pout_tagged --ctx register_env --msg "$(
      printf "\n  %${pad}s%s%s" " ${_var}" "${sep}" "${_val}"
    )"
  fi

  #~@ Handle path-specific variables
  if [ -e "${_val}" ]; then
    #~@ Define relational functions
    eval "ed_${_var}() { edit \"\${${_var}}\"; }"
  fi

  #~@ Handle directory-specific variables
  if [ -d "${_val}" ]; then
    #~@ Define relational functions
    eval "cd_${_var}() { cd \"\${${_var}}\"; }"

    #~@ Source the entrypoint, if it exists and the initialization flag is set
    if [ "${_init}" -eq 1 ] && [ -f "${_val}/${RC}" ]; then
      # shellcheck disable=SC1090  #? The file has been validated to exist
      . "${_val}/${RC}"

      #~@ Return the result of the sourced command
      return $?
    fi
  fi

  #~@ Handle file-specific variables
  if [ -f "${_val}" ]; then
    if [ "${_init}" -eq 1 ]; then
      #~@ Source the file if the initialization flag is set
      # shellcheck disable=SC1090  #? The file has been validated to exist
      . "${_val}"

      #~@ Return the result of the sourced command
      return $?
    fi
  fi
}

unregister_env() {
  env=$1
  unset "${env}" 2>/dev/null
  unset -f "ed_${env}" 2>/dev/null
  unset -f "cd_${env}" 2>/dev/null
  unalias "${env}" 2>/dev/null
}

resolve_env() {
  #~@ Validate arguments
  if [ -z "${1:-}" ]; then
    return 1
  fi

  #~@ Get the current value of the variable
  eval 'env="${'"${1}"'}"'

  if [ -z "${env:-}" ]; then
    return 1
  fi

  if [ -e "${env}" ]; then
    #~@ Retrieve the absolute path (if possible)
    if [ -d "${env}" ]; then
      (cd "${env}" 2>/dev/null && pwd)
    elif [ -f "${env}" ]; then

      #~@ For files: cd to dirname, then print full path
      dir=$(dirname "${env}")
      file=$(basename "${env}")
      (cd "${dir}" 2>/dev/null && printf "%s/%s\n" "$(pwd -P || true)" "${file}")
    fi
  else
    #~@ Return the value of the variable
    printf '%s\n' "${env}"
  fi
}

edit() {
  #~@ Ensure the EDITOR is set
  : "${EDITOR:=hx}"

  #~@ Launch with the specified arguments or the current directory
  if [ -n "${1:-}" ]; then
    eval "${EDITOR} -- \"\${@}\""
  else
    eval "${EDITOR} -- \"\$(pwd -P)\""
  fi
}

get_verbosity() {
  #~@ Set defaults
  : "${verbosity:=$1}"
  : "${verbosity:=${VERBOSITY}}"
  : "${verbosity:=1}"
  default_verbosity=3
  current_verbosity="$(
    printf "%s" "${verbosity}" | tr '[:upper:]' '[:lower:]' || true
  )"

  #~@ Set verbosity based on current verbosity
  case "${current_verbosity}" in
  0 | none | off | quiet | silent | false) verbosity=0 ;;
  1 | err* | low) verbosity=1 ;;
  2 | warn* | medium) verbosity=2 ;;
  3 | info* | normal) verbosity=3 ;;
  4 | debug | verbose | on) verbosity=4 ;;
  5 | trace | high) verbosity=5 ;;
  *)
    #~@ Handle edge cases
    case "${current_verbosity}" in
    -)
      #~@ Assume that a minus sign means to turn off verbosity
      verbosity=0
      ;;
    -[0-9]* | [0-9]*)
      #~@ Handle possible integer
      case "${current_verbosity}" in
      *[!0-9-]* | --*)
        #~@ Fallback as invalid characters exist in the string
        verbosity="${default_verbosity}"
        ;;
      *)
        #~@ Clamp integer to 0 and 5
        if [ "${current_verbosity}" -lt 0 ]; then
          verbosity=0
        elif [ "${current_verbosity}" -gt 5 ]; then
          verbosity=5
        else
          verbosity="${current_verbosity}"
        fi
        ;;
      esac
      ;;
    *)
      #~@ Fallbase as the current value is unknown
      verbosity="${default_verbosity}"
      ;;
    esac
    ;;
  esac

  #~@ Print the final verbosity level
  printf "%s" "${verbosity}"
}

pout_tagged() {
  #~@ Set a safe delimiter (ASCII Unit Separator)
  : "${DELIMITER:="$(printf "\037")"}"

  #~@ Initialize with defaults
  ctx=""
  tag=""
  msg=""

  #~@ Parse named arguments
  while [ $# -gt 0 ]; do
    case "${1}" in
    --ctx)
      if [ $# -gt 1 ]; then
        ctx="$2"
        shift
      else
        printf "Error: Missing value for --ctx\n" >&2
        return 1
      fi
      ;;
    --tag)
      if [ $# -gt 1 ]; then
        tag="$2"
        shift
      else
        printf "Error: Missing value for --tag\n" >&2
        return 1
      fi
      ;;
    --ctx=*)
      ctx="${1#--ctx=}"
      ;;
    --msg)
      if [ $# -gt 1 ]; then
        msg="${msg:+${msg}${DELIMITER}}$2"
        shift
      else
        printf "Error: Missing value for --msg\n" >&2
        return 1
      fi
      ;;
    --tag=*)
      tag="${1#--tag=}"
      ;;
    --)
      #~@ End of options
      shift
      ;;
    --*)
      #~@ Unknown option, ignore or warn
      ;;
    *)
      #~@ Collect message arguments, separated by DELIMITER
      msg="${msg:+${msg}${DELIMITER}}$1"
      ;;
    esac
    shift
  done

  #~@ Return early if no message is provided
  if [ -z "${msg}" ]; then
    return
  fi

  #~@ Fallback to context variables if not set
  if [ -z "${ctx}" ]; then ctx="${fn_name:-}"; fi
  if [ -z "${ctx}" ]; then ctx="${scr_name:-}"; fi
  if [ -z "${ctx}" ]; then ctx="${scr_path:-}"; fi
  if [ -z "${ctx}" ]; then ctx="Untitled"; fi

  #~@ Default tag to DEBUG if not provided
  if [ -z "${tag}" ]; then tag="DEBUG"; fi
  tag="$(printf "%s" "${tag}" | tr '[:lower:]' '[:upper:]')"

  #~@ Add aleading newline for separation
  printf "\n"

  #~@ Print the tag and context
  printf "%s >>= %s =<<" "${tag}" "${ctx}"

  #~@ Print all message arguments, split by DELIMITER
  if [ -n "${msg}" ]; then
    old_ifs=${IFS}
    IFS="${DELIMITER}"
    # shellcheck disable=SC2086
    set -- ${msg}
    IFS=${old_ifs}
    for arg in "$@"; do
      printf "%s" "${arg}"
    done

    #~@ Add a trailing newline for separation
    printf "\n"
  fi
}

main "$@"
