#! /bin/sh
# shellcheck disable=SC2154,SC1090

main() {
  set_defaults

  #{ Load the DOTS environment }
  manage_env --set --var DOTS --val "${DOTS}"
  manage_env --set --var HOME --val "${HOME}"
  manage_env --set --var DOTS_RC --val "${DOTS_RC}"
  manage_env --set --var BASH_RC --val "${HOME}/.bashrc"
  manage_env --set --var PROFILE --val "${HOME}/.profile"
  manage_env --set --var DOTS_TMP --val "${DOTS}/.cache"
  manage_env --init --var DOTS_CACHE --val "${DOTS_TMP}" #? Alias to DOTS_TMP
  manage_env --init --var DOTS_RES --val "${DOTS}/Assets" #? Resources don't depend on the environment
  manage_env --set --var DOTS_ENV --val "${DOTS}/Environment"
  manage_env --set --var DOTS_ENV_POSIX --val "${DOTS_ENV}/posix" #? This file, so no need to init
  manage_env --init --var DOTS_ENV_POSIX_CTX --val "${DOTS_ENV_POSIX:?}/context"
  manage_env --init --var DOTS_ENV_POSIX_PKG --val "${DOTS_ENV_POSIX:?}/packages"
  manage_env --init --var DOTS_ENV_OUTPUTCTRL --val "${DOTS_ENV_POSIX_CTX:?}/output.sh"
  manage_env --init --var DOTS_ENV_SYSTEMINFO --val "${DOTS_ENV_POSIX_CTX:?}/system.sh"
  manage_env --init --var DOTS_ENV_DIRECTORY --val "${DOTS_ENV_POSIX_CTX:?}/dirs.sh"
  # manage_env --init --var DOTS_ENV_HISTORY --val "${DOTS_ENV_POSIX_CTX:?}/history.sh"
  # manage_env --init --var DOTS_ENV_LOCALE --val "${DOTS_ENV_POSIX_CTX:?}/locale.sh"

  #{ Load other environment variables }
  # manage_env --init --var DOTS_BIN --val "${DOTS}/Bin"
  # manage_env --init --var DOTS_CFG --val "${DOTS}/Configuration"
  # manage_env --init --var DOTS_DLD --val "${DOTS}/Downloads"
  # manage_env --init --var DOTS_DOC --val "${DOTS}/Documentation"
  # manage_env --init --var DOTS_NIX --val "${DOTS}/Admin"

  # nu
}

set_defaults() {
  #|-> Output Configuration
  VERBOSITY="$(verbosity "Error")"
  VERBOSITY_QUIET=0
  VERBOSITY_ERROR=1
  VERBOSITY_WARN=2
  VERBOSITY_INFO=3
  VERBOSITY_DEBUG=4
  VERBOSITY_TRACE=5
  DELIMITER="$(printf "\037")"
  PAD=12
  SEP=" | "
  export DELIMITER VERBOSITY EDITOR VERBOSITY_QUIET VERBOSITY_ERROR VERBOSITY_WARN VERBOSITY_INFO VERBOSITY_DEBUG VERBOSITY_TRACE PAD SEP

  #|-> Editor Configuration
  : "${EDITORS_TUI:="helix, nvim, vim, nano"}"
  : "${EDITORS_GUI:="code, zed, zeditor, trae, notepad++, notepad"}"
  export EDITORS_TUI EDITORS_GUI
  EDITOR="$(editor --set)" export EDITOR

  #|-> DOTS Environment Entrypoint
  RC=".dotsrc" export RC
  DOTS_CACHE_RC="${DOTS:?}/.cache/.dotsrc" export DOTS_CACHE_RC
  #{ Load the cached rc file }
  if [ -f "${DOTS_CACHE_RC}" ]; then
    # shellcheck disable=SC1090
    . "${DOTS_CACHE_RC}"
  fi

  #|-> Commands
  CMD_RG="$(command -v rg 2>/dev/null || command -v grep 2>/dev/null)" export CMD_RG
}

manage_env() {
  #DOC Manage environment variables with various operations.
  #DOC
  #DOC Description:
  #DOC   This function provides a unified interface for managing environment
  #DOC   variables including registration, initialization, editing, and resolution.
  #DOC   It supports interactive prompting for overwrite confirmation and can
  #DOC   automatically create helper functions for paths and directories.
  #DOC
  #DOC Arguments:
  #DOC   -a, --action ACTION   Specify the action: register|set|unregister|unset|resolve|edit|init
  #DOC   -k, --var, --key VAR Specify the variable name to manage
  #DOC   -p, --val, --path VAL Specify the variable value/path
  #DOC   -f, --force, --yes    Force operation without prompting
  #DOC   -i, --init           Initialize/source the target if it's a file/directory
  #DOC   -E, --editor EDITOR  Specify the editor to use (default: hx)
  #DOC   --rc, --target FILE  Specify the RC file to use
  #DOC   -d, --debug          Enable debug verbosity
  #DOC   -h, --help           Display usage information
  #DOC
  #DOC Returns:
  #DOC   0 - Operation completed successfully
  #DOC   1 - Invalid arguments or operation failed
  #DOC
  #DOC Side Effects:
  #DOC   - Exports the specified variable globally
  #DOC   - Creates ed_VARNAME() function for files/directories
  #DOC   - Creates cd_VARNAME() function for directories
  #DOC   - Sources files when --init flag is used
  #DOC
  #DOC Examples:
  #DOC   # Register a new variable
  #DOC   manage_env --var MYPATH --val "/some/path"
  #DOC
  #DOC   # Force overwrite existing variable
  #DOC   manage_env --force --var MYPATH --val "/new/path"
  #DOC
  #DOC   # Register and initialize a directory (sources RC file if present)
  #DOC   manage_env --init --var DOTS --val "/path/to/dotfiles"
  #DOC
  #DOC   # Edit a variable's target
  #DOC   manage_env --action edit --var MYPATH
  #DOC
  #DOC   # Resolve a variable's current value
  #DOC   manage_env --action resolve --var MYPATH
  #DOC
  #DOC   # Unregister a variable and its functions
  #DOC   manage_env --action unregister --var MYPATH

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
    action="init"
    actions="edit | env | init | initialize | resolve | register | set | unregister | unset"
    var="" val="" args=""
    force=false
    # init=true
  }

  parse_arguments() {
    #{ Skip if no arguments are provided.
    [ $# -eq 0 ] && return 1

    #{ Parse command-line options
    while [ $# -ge 1 ]; do
      case "$1" in
      --help | -h)
        show_usage
        return 0
        ;;
      -[dD] | --debug | --verbose | -V) VERBOSITY="DEBUG" ;;
      -[fF] | -[yY] | --force | --yes) force=true ;;
      --ask | --interactive) force=false ;;
      -[iI] | --init | --initialize) action="init" ;;
      -R | --register | --set | -s) action="register" ;;
      -U | --unregister | -unset | -u) action="unregister" ;;
      -r | --resolve) action="resolve" ;;
      -e | --edit) action="edit" ;;
      -a | --action)
        if [ "$#" -lt 2 ]; then
          show_usage_error "Missing argument for '$1'"
          return 1
        fi
        shift
        if printf "%s" "${actions}" | grep -q "\\b${1}\\b"; then
          action=$1
        else
          show_usage_error "Invalid action '$1'. Must be one of: ${actions}"
          return 1
        fi
        ;;
      -E | --editor)
        if [ "$#" -lt 2 ]; then
          show_usage_error "Missing argument for '$1'"
          return 1
        fi
        shift
        EDITOR="$1"
        ;;
      --rc | --target)
        if [ "$#" -lt 2 ]; then
          show_usage_error "Missing argument for '$1'"
          return 1
        fi
        shift
        RC="$1"
        ;;
      -k | --key | --var)
        if [ "$#" -lt 2 ]; then
          show_usage_error "Missing argument for '$1'"
          return 1
        fi
        shift
        var="$1"
        ;;
      -p | --path | --val)
        if [ "$#" -lt 2 ]; then
          show_usage_error "Missing argument for '$1'"
          return 1
        fi
        shift
        val="$1"
        ;;
      *)
        args="${args:+${args}${DELIMITER}}$1"
        ;;
      esac
      shift
    done

    #{ Parse positional arguments if necessary
    if [ -n "${args}" ]; then
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
    fi

    #{ Validate required arguments based on action
    case "${action}" in
    register | set | init | initialize)
      # show_usage_error "Variable name is required for action '${action}'"
      if [ -z "${var:-}" ] && [ -z "${val:-}" ]; then
        return 1
      fi
      ;;
    unregister | unset | resolve | edit)
      if [ -z "${var:-}" ]; then
        # show_usage_error "Variable name is required for action '${action}'"
        return 1
      fi
      ;;
    *) ;;
    esac

    #{ Print debug information
    pout-tagged --ctx "${fn_name}" --tag "[DEBUG]" --msg "$(
      printf "\n%${PAD}s%s%s" "ACTION" "${SEP}" "${action}"
      printf "\n%${PAD}s%s%s" "ENV_var" "${SEP}" "${var}"
      printf "\n%${PAD}s%s%s" "ENV_val" "${SEP}" "${val}"
      # printf "\n%${PAD}s%s%s" "EDITOR" "${SEP}" "${EDITOR}"
      # printf "\n%${PAD}s%s%s" "RC" "${SEP}" "${RC}"
      printf "\n%${PAD}s%s%s" "FORCE" "${SEP}" "${force}"
    )"
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
      show_usage_error "Invalid action '${action}'. Must be one of: ${actions}"
      return 1
      ;;
    esac
  }

  show_usage() {
    printf 'Usage: %s [--action ACTION] [--var VAR] [--val VAL] [OPTIONS]\n' "${fn_name}"
    printf '\n'
    printf 'Actions:\n'
    printf '  register, set         Register/set a variable (default)\n'
    printf '  init, initialize      Register and initialize (source if file/dir)\n'
    printf '  unregister, unset     Remove a variable and its functions\n'
    printf '  resolve, env          Display the resolved value of a variable\n'
    printf '  edit                  Edit the target of a variable\n'
    printf '\n'
    printf 'Options:\n'
    printf '  -h, --help            Display this usage information\n'
    printf '  -a, --action ACTION   Specify the action to perform\n'
    printf '  -k, --var, --key VAR  Specify the variable name\n'
    printf '  -p, --val, --path VAL Specify the variable value/path\n'
    printf '  -f, --force, --yes    Force operation without prompting\n'
    printf '  -i, --init           Initialize/source the target\n'
    printf '  -E, --editor EDITOR  Specify the editor to use\n'
    printf '  --rc, --target FILE  Specify the RC file to use\n'
    printf '  -d, --debug          Enable debug output\n'
    printf '\n'
    printf 'Examples:\n'
    printf '  %s --var MYPATH --val /some/path\n' "${fn_name}"
    printf '  %s --force --var MYPATH --val /new/path\n' "${fn_name}"
    printf '  %s --action resolve --var MYPATH\n' "${fn_name}"
    printf '  %s --action edit --var MYPATH\n' "${fn_name}"
  }

  show_usage_error() {
    pout-tagged --ctx "${fn_name}" --tag "[ERROR]" --msg "$1"
    show_usage
  }

  main "$@"
}

resolve_env() {
  #DOC Resolve and return the absolute path of an environment variable.
  #DOC
  #DOC Arguments:
  #DOC   $1 - The variable name to resolve
  #DOC
  #DOC Returns:
  #DOC   0 - Variable exists and path was resolved
  #DOC   1 - Variable doesn't exist or is empty
  #DOC
  #DOC Output:
  #DOC   The resolved absolute path or variable value

  #{ Validate arguments
  if [ -z "${1:-}" ]; then
    return 1
  fi

  #{ Get the current value of the variable or quit }
  eval 'env="${'"${1}"'}"'
  if [ -z "${env:-}" ]; then return 1; fi

  #{ Convert Windows drive letter paths to Unix-style }
  case "${env}" in
  [a-zA-Z]:[\\/]*)
    drive_letter=$(
      printf '%s\n' "${env%%[\\/:]*}" |
        tr '[:upper:]' '[:lower:]'
    )                                                #? C:\path or C:/path to /c/path
    normalized_path=$(printf '%s\n' "${env#*[\\/]}") #? [\, \\] to  [/]
    env="/${drive_letter}/${normalized_path}"
    ;;
  *) ;;
  esac

  #{ Process the value }
  if [ -e "${env}" ]; then
    #{ Retrieve the absolute path (if possible)
    if [ -d "${env}" ]; then
      resolved="$(cd "${env}" 2>/dev/null && pwd)"
    elif [ -f "${env}" ]; then

      #{ For files: cd to dirname, then print full path
      dir="$(dirname "${env}")"
      file="$(basename "${env}")"
      resolved="$(cd "${dir}" 2>/dev/null && printf "%s/%s\n" "$(pwd -P || true)" "${file}")"
    fi
  else
    #{ Return the value of the variable
    resolved="$(printf '%s\n' "${env}")"
  fi

  #{ Escape all $ to \$ }
  printf '%s\n' "${resolved}" | sed 's/\$/\\\$/g'
  unset resolved
}

register_env() {
  #DOC Register an environment variable with optional initialization.
  #DOC
  #DOC Description:
  #DOC   Registers a variable in the environment, with interactive prompting
  #DOC   for overwrites unless forced. Creates helper functions for paths and
  #DOC   directories, and can optionally source/initialize the target.
  #DOC
  #DOC Arguments:
  #DOC   --force              Force overwrite without prompting
  #DOC   --init               Initialize/source the target after registration
  #DOC   --var VARIABLE       The variable name to register
  #DOC   --val VALUE          The value to assign to the variable
  #DOC
  #DOC Outputs:
  #DOC   - Exports the variable globally
  #DOC   - Creates ed_VARNAME() function for existing paths
  #DOC   - Creates cd_VARNAME() function for directories
  #DOC   - Sources RC files in directories when --init is used
  #DOC   - Sources files directly when --init is used

  #{ Set defaults }
  _val="" _var="" _args="" _init=0 _force=0

  #{ Parse arguments }
  while [ $# -ge 1 ]; do
    case "$1" in
    -[iI] | --init | --initialize) _init=1 ;;
    -[fF] | --force) _force=1 ;;
    --env-file)
      _env_file="$2"
      shift
      ;;
    --var)
      if [ $# -lt 2 ]; then
        show_usage_error "Missing argument for '$1'"
        return 1
      fi
      _var="$2"
      shift
      ;;
    --val)
      if [ $# -lt 2 ]; then
        show_usage_error "Missing argument for '$1'"
        return 1
      fi
      _val="$2"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*) ;; #? Unknown option, skip
    *) _args="${_args:+${_args}${DELIMITER}}$1" ;;
    esac
    shift
  done

  #{ Handle remaining arguments after -- separator }
  while [ $# -ge 1 ]; do
    _args="${_args:+${_args}${DELIMITER}}$1"
    shift
  done

  #{ Parse positional arguments if necessary }
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

  #{ Validate required arguments }
  if [ -z "${_var:-}" ] || [ -z "${_val:-}" ]; then
    # show_usage_error "Variable value is required"
    return 1
  fi

  #{ Debug arguments }
  pout-tagged --ctx "register_env" --tag "DEBUG" --msg "$(
    printf "\n  %${PAD}s%s%s" "INIT" "${SEP}" "${_init}"
    printf "\n  %${PAD}s%s%s" "FORCE" "${SEP}" "${_force}"
    printf "\n  %${PAD}s%s%s" "VAR" "${SEP}" "${_var}"
    printf "\n  %${PAD}s%s%s" "VAL" "${SEP}" "${_val}"
  )"

  #{ Handle existing variable values }
  var_val="$(resolve_env "${_var}" 2>/dev/null || true)"
  case "${var_val:-}" in
  "")
    #? Variable doesn't exist, use argument value
    pout-tagged --ctx "register_env" --tag "[INFO]" \
      "Registering new variable ${_var}=${_val}"
    ;;
  "${_val}")
    #? System value matches argument value - no change needed
    if grep -q "${_var}=" "${DOTS_CACHE_RC}" 2>/dev/null; then
      pout-tagged --ctx "register_env" --tag "[TRACE]" \
        "Variable ${_var} already set to correct value"
      return 0
    fi
    ;;
  *)
    #? System value differs from argument value
    case "${_force}" in 1 | true | yes | on)
      pout-tagged --ctx "register_env" --tag "[WARN]" \
        "Forcing overwrite of ${_var}: '${var_val}' -> '${_val}'"
      ;;
    *)
      #? Interactive overwrite
      #{ Interactive prompt for overwrite }
      printf "Variable '%s' is already set to: '%s'\n" "${_var}" "${var_val}"
      printf "New value would be: '%s'\n" "${_val}"
      printf "Overwrite with new value? [y/N] (default: N): "

      #{ Handle CTRL-C during read }
      trap 'echo "\nCancelled by user"; _val="${var_val}"; trap - INT' INT
      read -r response
      trap - INT

      case "${response}" in
      [Yy]*)
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "User confirmed overwrite of ${_var}"
        fi
        ;;
      *)
        _val="${var_val}"
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "User declined overwrite, keeping existing value"
        fi
        ;;
      esac
      ;;
    esac
    ;;
  esac

  #{ Escape all $ in _val to ensure literal $ in paths when RC is sourced }
  _escaped_val=$(printf '%s\n' "${_val}" | sed 's/\$/\\\$/g')

  #{ Register the variable globally }
  printf "\nexport %s=\"%s\"" "${_var}" "${_escaped_val}" >>"${DOTS_CACHE_RC}"
  . "${DOTS_CACHE_RC}"
  pout-tagged --ctx "register_env" --tag "[DEBUG]" --msg "Exported ${_var}=${_escaped_val}"

  #{ Create helper functions for existing paths }
  if [ -e "${_val}" ]; then
    printf "\ned_%s(){ editor \"%s\" || exit 1 ;}" \
      "${_var}" "${_escaped_val}" >>"${DOTS_CACHE_RC}"
    pout-tagged --ctx "register_env" --tag "[DEBUG]" \
      "Created function ed_${_var}"
  fi

  #{ Handle directory-specific functionality }
  if [ -d "${_val}" ]; then
    printf "\ncd_%s(){ cd \"%s\" || exit 1 ;}" \
      "${_var}" "${_escaped_val}" >>"${DOTS_CACHE_RC}"
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_DEBUG:-4}" ]; then
      pout-tagged --ctx "register_env" --tag "[DEBUG]" --msg "Created function cd_${_var}"
    fi

    #{ Source all RC files if initialization is requested }
    if [ "${_init}" -eq 1 ]; then
      #{ Loop over all matching RC files and source each if it exists }
      for rc_file in "${_val}/${RC}" "${_val}/${RC}.sh" "${_val}/${RC}.bash" "${_val}/${RC}.zsh"; do
        if [ -f "${rc_file}" ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "Sourced ${rc_file}"
          #{ Source the RC file if initialization is requested }
          # shellcheck disable=SC2250,SC1090 #? We already validated this file
          . "${rc_file}"
          return $?
        fi
      done
    fi
  fi

  #{ Handle file-specific initialization }
  if [ -f "${_val}" ] && [ "${_init}" -eq 1 ]; then
    # shellcheck disable=SC1090
    . "${_val}"
    pout-tagged --ctx "register_env" --tag "[INFO]" --msg "Sourced ${_val}"
  fi

  return 0
}

register_env_OLD() {
  #DOC Register an environment variable with optional initialization.
  #DOC
  #DOC Description:
  #DOC   Registers a variable in the environment, with interactive prompting
  #DOC   for overwrites unless forced. Creates helper functions for paths and
  #DOC   directories, and can optionally source/initialize the target.
  #DOC
  #DOC Arguments:
  #DOC   --force              Force overwrite without prompting
  #DOC   --init               Initialize/source the target after registration
  #DOC   --var VARIABLE       The variable name to register
  #DOC   --val VALUE          The value to assign to the variable
  #DOC
  #DOC Side Effects:
  #DOC   - Exports the variable globally
  #DOC   - Creates ed_VARNAME() function for existing paths
  #DOC   - Creates cd_VARNAME() function for directories
  #DOC   - Sources RC files in directories when --init is used
  #DOC   - Sources files directly when --init is used

  #{ Set defaults }
  _val="" _var="" _args="" _init=0 _force=0

  #{ Parse arguments }
  while [ $# -ge 1 ]; do
    case "$1" in
    -[iI] | --init | --initialize) _init=1 ;;
    -[fF] | --force) _force=1 ;;
    --env-file) _env_file="$2" ;;
    --var)
      if [ $# -lt 2 ]; then
        show_usage_error "Missing argument for '$1'"
        return 1
      fi
      _var="$2"
      shift
      ;;
    --val)
      if [ $# -lt 2 ]; then
        show_usage_error "Missing argument for '$1'"
        return 1
      fi
      _val="$2"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*) ;; #? Unknown option, skip
    *) _args="${_args:+${_args}${DELIMITER}}$1" ;;
    esac
    shift
  done

  #{ Handle remaining arguments after -- separator }
  while [ $# -ge 1 ]; do
    _args="${_args:+${_args}${DELIMITER}}$1"
    shift
  done

  #{ Parse positional arguments if necessary }
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

  #{ Validate required arguments }
  if [ -z "${_var:-}" ] || [ -z "${_val:-}" ]; then
    # show_usage_error "Variable value is required"
    return 1
  fi

  #{ Debug arguments }
  pout-tagged --ctx "register_env" --tag "DEBUG" --msg "$(
    printf "\n  %${PAD}s%s%s" "INIT" "${SEP}" "${_init}"
    printf "\n  %${PAD}s%s%s" "FORCE" "${SEP}" "${_force}"
    printf "\n  %${PAD}s%s%s" "VAR" "${SEP}" "${_var}"
    printf "\n  %${PAD}s%s%s" "VAL" "${SEP}" "${_val}"
  )"

  #{ Convert Windows paths to POSIX-compliant format }
  # case "${_val}" in
  #     [A-Za-z]:[\\/]*)  # Match drive letters (e.g., C:\ or D:/)
  #         # Extract drive letter and convert to lowercase
  #         _drive="/$(echo "${_val%%[\\/]*}" | tr '[:upper:]' '[:lower:]' | tr -d ':')"
  #         # Convert backslashes to forward slashes and prepend drive letter
  #         _val="/${_drive}${_val#*[\\/]}" | tr '\\' '/'
  #         ;;
  #     *) ;;  # Leave non-Windows paths unchanged
  # esac

  #{ Handle existing variable values }
  var_val="$(resolve_env "${_var}" 2>/dev/null || true)"
  case "${var_val:-}" in
  "")
    #? Variable doesn't exist, use argument value
    pout-tagged --ctx "register_env" --tag "[INFO]" \
      "Registering new variable ${_var}=${_val}"
    ;;
  "${_val}")
    #? System value matches argument value - no change needed
    if grep -q "${_var}=" "${DOTS_CACHE_RC}" 2>/dev/null; then
      pout-tagged --ctx "register_env" --tag "[TRACE]" \
        "Variable ${_var} already set to correct value"
      return 0
    fi
    ;;
  *)
    #? System value differs from argument value
    case "${_force}" in 1 | true | yes | on)
      pout-tagged --ctx "register_env" --tag "[WARN]" \
        "Forcing overwrite of ${_var}: '${var_val}' -> '${_val}'"
      ;;
    *)
      #? Interactive overwrite
      #{ Interactive prompt for overwrite }
      printf "Variable '%s' is already set to: '%s'\n" "${_var}" "${var_val}"
      printf "New value would be: '%s'\n" "${_val}"
      printf "Overwrite with new value? [y/N] (default: N): "

      #{ Handle CTRL-C during read }
      trap 'echo "\nCancelled by user"; _val="${var_val}"; trap - INT' INT
      read -r response
      trap - INT

      case "${response}" in
      [Yy]*)
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "User confirmed overwrite of ${_var}"
        fi
        ;;
      *)
        _val="${var_val}"
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "User declined overwrite, keeping existing value"
        fi
        ;;
      esac
      ;;
    esac
    ;;
  esac

  #{ Register the variable globally }
  printf "\nexport %s=\"%s\"" "${_var}" "${_val}" >>"${DOTS_CACHE_RC}"
  . "${DOTS_CACHE_RC}"
  pout-tagged --ctx "register_env" --tag "[DEBUG]" --msg "Exported ${_var}=${_val}"

  #{ Create helper functions for existing paths }
  if [ -e "${_val}" ]; then
    printf "\ned_%s(){ editor \"%s\" || exit 1 ;}" \
      "${_var}" "${_val}" >>"${DOTS_CACHE_RC}"
    pout-tagged --ctx "register_env" --tag "[DEBUG]" \
      "Created function ed_${_var}"
  fi

  #{ Handle directory-specific functionality }
  if [ -d "${_val}" ]; then
    printf "\ncd_%s(){ cd \"%s\" || exit 1 ;}" \
      "${_var}" "${_val}" >>"${DOTS_CACHE_RC}"
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_DEBUG:-4}" ]; then
      pout-tagged --ctx "register_env" --tag "[DEBUG]" --msg "Created function cd_${_var}"
    fi

    #{ Source all RC files if initialization is requested }
    if [ "${_init}" -eq 1 ]; then

      #{ Loop over all matching RC files and source each if it exists }
      for rc_file in "${_val}/${RC}" "${_val}/${RC}.sh" "${_val}/${RC}.bash" "${_val}/${RC}.zsh"; do
        if [ -f "${rc_file}" ]; then
          pout-tagged --ctx "register_env" --tag "[INFO]" --msg "Sourced ${rc_file}"

          #{ Source the RC file if initialization is requested }
          # shellcheck disable=SC2250,SC1090 #? We already validated this file
          . "${rc_file}"
          return $?
        fi
      done
    fi
  fi

  #{ Handle file-specific initialization }
  if [ -f "${_val}" ] && [ "${_init}" -eq 1 ]; then
    # shellcheck disable=SC1090
    . "${_val}"
    pout-tagged --ctx "register_env" --tag "[INFO]" --msg "Sourced ${_val}"
  fi

  return 0
}

unregister_env() {
  #DOC Remove an environment variable and its associated functions.
  #DOC
  #DOC Arguments:
  #DOC   $1 - The variable name to unregister
  #DOC
  #DOC Side Effects:
  #DOC   - Removes export and functions if they exist in ${DOTS_CACHE_RC}
  #DOC   - Unsets the specified environment variable
  #DOC   - Removes any aliases with the variable name

  env="$1"
  if [ -z "${env:-}" ]; then
    pout-tagged --ctx "unregister_env" --tag "[ERROR]" --msg "Variable name is required"
    return 1
  else
    pout-tagged --ctx "unregister_env" --tag "[INFO]" --msg "Unregistering ${env}"
  fi

  #{ Remove environment export, aliases, and helper functions (ending with _${env}) }
  sed -i \
    -e "/^alias ${env}=/d" \
    -e "/^export ${env}=/d" \
    -e "/^[a-zA-Z0-9_]*_${env}(){.*}/d" \
    "${DOTS_CACHE_RC}"

  #{ Remove aliases with the variable name from the current shell }
  unset "${env}" 2>/dev/null
  for prefix in ed cd ls mv; do #? add more as needed
    unset -f "${prefix}_${env}" 2>/dev/null
  done
  unalias "${env}" 2>/dev/null
  unset "${env}" 2>/dev/null
}

parse_list() {
  # Usage: parse_list "list_of_items"
  list="${1}"

  #{ Store processed items in a variable }
  processed_items="$(
    printf '%s' "${list}" | sed '
      /^[[:space:]]*#/d;                 # Remove comment lines
      s/#.*$//;                          # Remove inline comments
      s/^[[:space:]]*//;                 # Remove leading whitespace
      s/[[:space:]]*$//;                 # Remove trailing whitespace
      s/[[:space:]]\+/'"${DELIMITER}"'/g; # Convert whitespace to delimiters
      /^$/d                              # Remove empty lines
    ' | tr '\n' "${DELIMITER}"
  )" #? Convert newlines to delimiter

  #{ Return the processed list }
  printf '%s' "${processed_items}"
}

copy_config() {
  src_cfg="${1}"
  des_cfg="${2}"

  #{ Validate source }
  if [ ! -f "${src_cfg}" ]; then
    pout-tagged --ctx "copy_config" --tag "[ERROR]" \
      "Missing source config: '${src_cfg}'"
    return 1
  fi

  #{ Skip if the destination already exists and is the same }
  if
    [ -f "${des_cfg}" ] && cmp -s "${src_cfg}" "${des_cfg}"
  then
    pout-tagged --ctx "copy_config" --tag "[INFO]" \
      "Skipping existing config: '${des_cfg}'"
    return 0
  fi

  #{ Create the destination directory }
  config_dir=$(dirname "${des_cfg}")
  if ! mkdir -p "${config_dir}"; then
    pout-tagged --ctx "copy_config" --tag "[ERROR]" \
      "Failed to create config directory: '${config_dir}'"
    return 1
  fi

  #{ Create a temporary copy of the source file }
  config_tmpfile="${des_cfg}.tmp_$$"
  if ! cp -f "${src_cfg}" "${config_tmpfile}"; then
    pout-tagged --ctx "copy_config" --tag "[ERROR]" \
      "Failed to create temporary file: '${config_tmpfile}'"
    return 1
  fi

  if ! mv -f "${config_tmpfile}" "${des_cfg}"; then
    pout-tagged --ctx "copy_config" --tag "[ERROR]" \
      "Failed to atomically update config: '${des_cfg}'"
    return 1
  fi

  unset config_dir config_tmpfile src dest
}

init_rc() {
  #{ Get the uncommented items from the list
  items=$(parse_list "${1:?"Missing list of rc files"}")

  OLD_IFS="${IFS}"
  IFS="${DELIMITER}"
  count=0
  for item in ${items}; do
    [ -z "${item}" ] && continue
    count=$((count + 1))
    path="${item}"

    if [ ! -f "${path}" ]; then
      pout-tagged --ctx "init_rc" --tag "[ERROR]" \
        "Missing rc file: '${path}'"
      continue
    else
      pout-tagged --ctx "init_rc" --tag "[TRACE]" "Sourcing '${path}'"
      # shellcheck disable=SC1090
      . "${path}"
    fi
  done
  IFS="${OLD_IFS}"
}

main
