#! /bin/sh
# shellcheck disable=SC2154

#{ Set global output levels
VERBOSITY="$(verbosity "Error")"
VERBOSITY_QUIET="$(verbosity "${VERBOSITY_QUIET}" 0)"
VERBOSITY_ERROR="$(verbosity "${VERBOSITY_ERROR}" 1)"
VERBOSITY_WARN="$(verbosity "${VERBOSITY_WARN}" 2)"
VERBOSITY_INFO="$(verbosity "${VERBOSITY_INFO}" 3)"
VERBOSITY_DEBUG="$(verbosity "${VERBOSITY_DEBUG}" 4)"
VERBOSITY_TRACE="$(verbosity "${VERBOSITY_TRACE}" 5)"
DELIMITER="$(printf "\037")"
export DELIMITER VERBOSITY EDITOR VERBOSITY_QUIET VERBOSITY_ERROR VERBOSITY_WARN VERBOSITY_INFO VERBOSITY_DEBUG VERBOSITY_TRACE

#{ Set common global variables
export RC=".dotsrc"
export EDITOR_TUI="helix, nvim, vim, nano"
export EDITOR_GUI="trae,code, zed, zeditor, trae, notepad++, notepad"
EDITOR="$(editor --set)" export EDITOR

#{ Set local variables
pad=12
sep=" | "

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
    action="register"
    actions="edit | env | init | initialize | resolve | register | set | unregister | unset"
    var="" val="" args=""
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

    pad="$(printf "%${pad}s" "")"
    pout-tagged --ctx "${fn_name}" --tag "DEBUG" \
      --msg "\n  ${pad}ACTION${sep}${action}" \
      --msg "\n  ${pad}ENV_var${sep}${var}" \
      --msg "\n  ${pad}ENV_val${sep}${val}" \
      --msg "\n  ${pad}EDITOR${sep}${EDITOR}" \
      --msg "\n  ${pad}RC${sep}${RC}" \
      --msg "\n  ${pad}FORCE${sep}${force}" \
      --msg "\n  ${pad}INIT${sep}${init}"

    #   printf "\n  %${pad}s%s%s" "ACTION" "${sep}" "${action}"
    #   printf "\n  %${pad}s%s%s" "ENV_var" "${sep}" "${var}"
    #   printf "\n  %${pad}s%s%s" "ENV_val" "${sep}" "${val}"
    #   printf "\n  %${pad}s%s%s" "EDITOR" "${sep}" "${EDITOR}"
    #   printf "\n  %${pad}s%s%s" "RC" "${sep}" "${RC}"
    #   printf "\n  %${pad}s%s%s" "FORCE" "${sep}" "${force}"

    #{ Print debug information
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_DEBUG:-4}" ]; then
      pout-tagged --ctx "${fn_name}" --tag "DEBUG" --msg "$(
        printf "\n  %${pad}s%s%s" "ACTION" "${sep}" "${action}"
        printf "\n  %${pad}s%s%s" "ENV_var" "${sep}" "${var}"
        printf "\n  %${pad}s%s%s" "ENV_val" "${sep}" "${val}"
        printf "\n  %${pad}s%s%s" "EDITOR" "${sep}" "${EDITOR}"
        printf "\n  %${pad}s%s%s" "RC" "${sep}" "${RC}"
        printf "\n  %${pad}s%s%s" "FORCE" "${sep}" "${force}"
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
    pout-tagged --ctx "${fn_name}" --tag "ERROR" --msg "$1"
    show_usage
  }

  main "$@"
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
  #DOC Side Effects:
  #DOC   - Exports the variable globally
  #DOC   - Creates ed_VARNAME() function for existing paths
  #DOC   - Creates cd_VARNAME() function for directories
  #DOC   - Sources RC files in directories when --init is used
  #DOC   - Sources files directly when --init is used

  #{ Set defaults
  _val="" _var="" _args="" _init=0 _force=0

  #{ Parse arguments
  while [ $# -ge 1 ]; do
    case "$1" in
    -[iI] | --init | --initialize) _init=1 ;;
    -[fF] | --force) _force=1 ;;
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

  #{ Handle remaining arguments after -- separator
  while [ $# -ge 1 ]; do
    _args="${_args:+${_args}${DELIMITER}}$1"
    shift
  done

  #{ Parse positional arguments if necessary
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

  #{ Validate required arguments
  if [ -z "${_var:-}" ] || [ -z "${_val:-}" ]; then
    # show_usage_error "Variable value is required"
    return 1
  fi

  if [ "${VERBOSITY:-0}" -ge 4 ]; then
    pout-tagged --ctx "register_env" --tag "DEBUG" --msg "$(
      printf "\n  %${pad}s%s%s" "INIT" "${sep}" "${_init}"
      printf "\n  %${pad}s%s%s" "FORCE" "${sep}" "${_force}"
      printf "\n  %${pad}s%s%s" "VAR" "${sep}" "${_var}"
      printf "\n  %${pad}s%s%s" "VAL" "${sep}" "${_val}"
    )"
  fi

  #{ Handle existing variable values
  var_val="$(resolve_env "${_var}" 2>/dev/null || true)"
  case "${var_val:-}" in
  "")
    #? Variable doesn't exist, use argument value
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_INFO:-3}" ]; then
      pout-tagged --ctx "register_env" --tag "INFO " --msg "Registering new variable ${_var}=${_val}"
    fi
    ;;
  "${_val}")
    #? System value matches argument value - no change needed
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_TRACE:-5}" ]; then
      pout-tagged --ctx "register_env" --tag "TRACE" --msg "Variable ${_var} already set to correct value"
    fi
    ;;
  *)
    #? System value differs from argument value
    if [ "${_force}" -eq 1 ]; then
      if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_WARN:-2}" ]; then
        pout-tagged --ctx "register_env" --tag "WARN " --msg "Forcing overwrite of ${_var}: '${var_val}' -> '${_val}'"
      fi
    else
      #{ Interactive prompt for overwrite
      printf "Variable '%s' is already set to: '%s'\n" "${_var}" "${var_val}"
      printf "New value would be: '%s'\n" "${_val}"
      printf "Overwrite with new value? [y/N] (default: N): "

      #{ Handle CTRL-C during read
      trap 'echo "\nCancelled by user"; _val="${var_val}"; trap - INT' INT
      read -r response
      trap - INT

      case "${response}" in
      [Yy]*)
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "INFO " --msg "User confirmed overwrite of ${_var}"
        fi
        ;;
      *)
        _val="${var_val}"
        if [ "${VERBOSITY:-0}" -ge 3 ]; then
          pout-tagged --ctx "register_env" --tag "INFO " --msg "User declined overwrite, keeping existing value"
        fi
        ;;
      esac
    fi
    ;;
  esac

  #{ Register the variable globally
  eval "${_var}=\"\${_val}\""
  eval "export ${_var}"

  if [ "${VERBOSITY:-0}" -ge 4 ]; then
    pout-tagged --ctx "register_env" --tag "DEBUG" --msg "Exported ${_var}=${_val}"
  fi

  #{ Create helper functions for existing paths
  if [ -e "${_val}" ]; then
    eval "ed_${_var}() { edit \"\${${_var}}\"; }"
    if [ "${VERBOSITY:-0}" -ge 4 ]; then
      pout-tagged --ctx "register_env" --tag "DEBUG" --msg "Created function ed_${_var}()"
    fi
  fi

  #{ Handle directory-specific functionality
  if [ -d "${_val}" ]; then
    eval "cd_${_var}() { cd \"\${${_var}}\"; }"
    if [ "${VERBOSITY:-0}" -ge "${VERBOSITY_DEBUG:-4}" ]; then
      pout-tagged --ctx "register_env" --tag "DEBUG" --msg "Created function cd_${_var}"
    fi

    #{ Source all RC files if initialization is requested
    if [ "${_init}" -eq 1 ]; then

      #{ Loop over all matching RC files and source each if it exists
      for rc_file in "${_val}/${RC}" "${_val}/${RC}.sh" "${_val}/${RC}.bash" "${_val}/${RC}.zsh"; do
        if [ -f "${rc_file}" ]; then

          if [ "${VERBOSITY:-0}" -ge 3 ]; then
            pout-tagged --ctx "register_env" --tag "INFO " --msg "Sourced ${rc_file}"
          fi

          # #{ Source the RC file if initialization is requested
          # shellcheck disable=SC2250,SC1090 #? We already validated this file
          . "${rc_file}"
          return $?
        fi
      done
    fi
  fi

  #{ Handle file-specific initialization
  if [ -f "${_val}" ] && [ "${_init}" -eq 1 ]; then
    # shellcheck disable=SC1090
    . "${_val}"
    if [ "${VERBOSITY:-0}" -ge 3 ]; then
      pout-tagged --ctx "register_env" --tag "INFO " --msg "Sourced ${_val}"
    fi
    return $?
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
  #DOC   - Unsets the specified environment variable
  #DOC   - Removes ed_VARNAME() function if it exists
  #DOC   - Removes cd_VARNAME() function if it exists
  #DOC   - Removes any aliases with the variable name

  env="$1"
  if [ -z "${env:-}" ]; then
    pout-tagged --ctx "unregister_env" --tag "ERROR" --msg "Variable name is required"
    return 1
  fi

  if [ "${VERBOSITY:-0}" -ge 3 ]; then
    pout-tagged --ctx "unregister_env" --tag "INFO " --msg "Unregistering ${env}"
  fi

  unset "${env}" 2>/dev/null
  unset -f "ed_${env}" 2>/dev/null
  unset -f "cd_${env}" 2>/dev/null
  unalias "${env}" 2>/dev/null
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

  #{ Get the current value of the variable
  eval 'env="${'"${1}"'}"'

  if [ -z "${env:-}" ]; then
    return 1
  fi

  if [ -e "${env}" ]; then
    #{ Retrieve the absolute path (if possible)
    if [ -d "${env}" ]; then
      (cd "${env}" 2>/dev/null && pwd)
    elif [ -f "${env}" ]; then

      #{ For files: cd to dirname, then print full path
      dir=$(dirname "${env}")
      file=$(basename "${env}")
      (cd "${dir}" 2>/dev/null && printf "%s/%s\n" "$(pwd -P || true)" "${file}")
    fi
  else
    #{ Return the value of the variable
    printf '%s\n' "${env}"
  fi
}

parse_list() {
  # Usage: parse_list "list_of_items"
  list="${1}"

  # Store processed items in a variable
  processed_items=$(printf '%s' "${list}" | sed '
        /^[[:space:]]*#/d;                 # Remove comment lines
        s/#.*$//;                          # Remove inline comments
        s/^[[:space:]]*//;                 # Remove leading whitespace
        s/[[:space:]]*$//;                 # Remove trailing whitespace
        s/[[:space:]]\+/'"${DELIMITER}"'/g; # Convert whitespace to delimiters
        /^$/d;                             # Remove empty lines
    ')

  # Return the processed list
  printf '%s' "${processed_items}"
}

init_rc() {
  #{ Get the uncommented items from the list
  items=$(parse_list "${1:?"Missing list of rc files"}")

  OLD_IFS="${IFS}"
  IFS="${DELIMITER}"
  for item in ${items}; do
    [ -z "${item}" ] && continue
    path="${DOTS_ENV_EXPORT}/${item}"
    # printf "Sourcing '%s'\n" "${path}"
    # shellcheck disable=SC1090
    . "${path}"
  done
  IFS="${OLD_IFS}"
}

#{ Load the DOTS environment
# shellcheck disable=SC2153
if command -v manage_env >/dev/null 2>&1; then
  manage_env --force --var DOTS --val "${DOTS}"
  manage_env --force --var HOME --val "${HOME}"
  manage_env --force --var DOTS_RC --val "${DOTS_RC}"
  # manage_env --force --var BASH_RC --val "${HOME}/.bashrc"
  # manage_env --force --var PROFILE --val "${HOME}/.profile"
  # manage_env --force --var DOTS_ENV --val "${DOTS}/Environment"
  # manage_env --force --init --var DOTS_ENV_POSIX --val "${DOTS_ENV}/posix"
  # manage_env --force --init --var DOTS_ENV_EXPORT --val "${DOTS_ENV_POSIX}/export"
  # manage_env --force --var DOTS_ENV_CONTEXT --val "${DOTS_ENV_POSIX}/context"
  # manage_env --force --init --var DOTS_BIN --val "${DOTS}/Bin"
  # manage_env --force --init --var DOTS_CFG --val "${DOTS}/Configuration"
  # manage_env --force --init --var DOTS_DLD --val "${DOTS}/Downloads"
  # manage_env --force --init --var DOTS_DOC --val "${DOTS}/Documentation"
  # manage_env --force --init --var DOTS_NIX --val "${DOTS}/Admin"
  # manage_env --force --init --var DOTS_TMP --val "${DOTS}/.cache"
else
  DOTS_ENV="${DOTS}/Environment" export DOTS_ENV
  DOTS_BIN="${DOTS}/Bin" export DOTS_BIN
  DOTS_CFG="${DOTS}/Configuration" export DOTS_CFG
  DOTS_DLD="${DOTS}/Downloads" export DOTS_DLD
  DOTS_DOC="${DOTS}/Documentation" export DOTS_DOC
  DOTS_NIX="${DOTS}/Admin" export DOTS_NIX
  DOTS_TMP="${DOTS}/.cache" export DOTS_TMP

  # shellcheck disable=SC1090
  for dir in "${DOTS_BIN}" "${DOTS_CFG}" "${DOTS_DLD}" "${DOTS_DOC}" "${DOTS_NIX}" "${DOTS_TMP}"; do
    if [ -f "${dir}/${RC}.sh" ]; then
      . "${dir}/${RC}.sh"
    fi
    if [ -n "${BASH_VERSION}" ] && [ -f "${dir}/${RC}.bash" ]; then
      . "${dir}/${RC}.bash"
    fi
    if [ -n "${ZSH_VERSION}" ] && [ -f "${dir}/${RC}.zsh" ]; then
      . "${dir}/${RC}.zsh"
    fi
  done
fi

main "$@"
