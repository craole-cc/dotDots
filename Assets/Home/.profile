#!/bin/sh
# shellcheck enable=all
scr_name=".profile"

#DOC Print a message with optional timestamp, verbosity, and context.
#DOC
#DOC  Args:
#DOC    --timestamp       Include a timestamp in the output.
#DOC    --trace           Print the message with TRACE verbosity.
#DOC    --debug           Print the message with DEBUG verbosity.
#DOC    --info            Print the message with INFO verbosity.
#DOC    --warn            Print the message with WARN verbosity.
#DOC    --error           Print the message with ERROR verbosity.
#DOC    --ctx             Set the context for the message.
#DOC    msg               The message to print.
#DOC
#DOC  Returns:
#DOC    The printed message.
_pout() {
  unset tag timestamp ctx msg

  #@ Normalize verbosity
  case "${verbosity}" in
  5 | trace) verbosity=5 ;;
  4 | debug) verbosity=4 ;;
  3 | info) verbosity=3 ;;
  2 | warn) verbosity=2 ;;
  1 | error) verbosity=1 ;;
  0 | quiet) verbosity=0 ;;
  *) ;; esac

  msg="$(printf '%s' "$*" | sed 's/[[:space:]]*$//')"

  while [ $# -ge 1 ]; do
    case "$1" in
    --timestamp)
      timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
      ;;
    --trace)
      if [ "${verbosity:-0}" -lt 5 ]; then return; else
        tag="$(printf "\033[0;35m%s\033[0m" "TRACE")"
      fi
      ;;
    --debug)
      if [ "${verbosity:-0}" -lt 4 ]; then return; else
        tag="$(printf "\033[0;33m%s\033[0m" "DEBUG")"
      fi
      ;;
    --info)
      if [ "${verbosity:-0}" -lt 3 ]; then return; else
        tag="$(printf "\033[0;32m%s\033[0m" "INFO")"
      fi
      ;;
    --warn)
      if [ "${verbosity:-0}" -lt 2 ]; then return; else
        tag="$(printf "\033[0;31m%s\033[0m" "WARN")"
      fi
      ;;
    --error)
      if [ "${verbosity:-0}" -lt 1 ]; then return; else
        tag="$(printf "\033[0;31m%s\033[0m" "ERROR")"
      fi
      ;;
    *) msg="${msg:-}$1" ;;
    esac
    shift
  done

  #@ Print the message
  if [ -n "${tag:-}" ]; then
    #@ Define the timestamp
    if [ -z "${timestamp:-}" ]; then :; else
      printf "%s " "${timestamp}"
    fi

    #@ Define the context
    if [ -n "${fn_name:-}" ]; then
      ctx="${ctx:-" |> ${scr_name} | ${fn_name} <| "}"
    else
      ctx="${ctx:-" |> ${scr_name} <| "}"
    fi

    printf "%s%s%b\n" \
      "${tag}" "${ctx}" "${msg}"
  else
    printf "%b\n""${msg}"
  fi
}

#DOC Update local git configuration to include the main gitconfig from DOTS.
#DOC
#DOC Description:
#DOC   This function manages the git configuration include paths to ensure
#DOC   the main gitconfig from DOTS is properly included. It removes any
#DOC   existing duplicate paths and adds the current DOTS path as the last
#DOC   include entry.
#DOC
#DOC Arguments:
#DOC   None (uses global DOTS variable)
#DOC
#DOC Returns:
#DOC   0 - If gitconfig is updated successfully
#DOC   1 - If DOTS is not set or main.gitconfig doesn't exist
#DOC
#DOC Example:
#DOC   update_gitconfig
update_gitconfig() {
  main() {
    trap 'cleanup' EXIT HUP INT TERM
    set_defaults
    execute_process
  }

  set_defaults() {
    cleanup() {
      unset fn_name gitconfig_path main_gitconfig_path temp_file
      [ -f "${temp_file:-}" ] && rm -f "${temp_file}"
    } && cleanup

    fn_name="update_gitconfig"
    gitconfig_path="${HOME}/.gitconfig"
    main_gitconfig_path="${DOTS}/Configuration/git/main.gitconfig"
    temp_file="${HOME}/.gitconfig.tmp.$(date +%Y%m%d_%H%M%S).$"
  }

  execute_process() {
    #@ Check if DOTS is set and main.gitconfig exists
    if [ -z "${DOTS:-}" ]; then
      _pout --warn "DOTS variable not set, skipping git configuration update"
      return 1
    fi

    if [ ! -f "${main_gitconfig_path}" ]; then
      _pout --warn "Main gitconfig not found at: ${main_gitconfig_path}"
      return 1
    fi

    _pout --debug "Updating git configuration to include: ${main_gitconfig_path}"

    #@ Create .gitconfig if it doesn't exist
    if [ ! -f "${gitconfig_path}" ]; then
      _pout --info "Creating new .gitconfig at: ${gitconfig_path}"
      touch "${gitconfig_path}"
    fi

    #@ Create temporary file for processing
    true >"${temp_file}"

    #@ Process the gitconfig file
    {
      #@ Copy everything except existing include paths to main.gitconfig
      awk '
        BEGIN { in_include = 0; skip_next = 0 }
        /^\[include\]/ { in_include = 1; print; next }
        /^\[/ && !/^\[include\]/ { in_include = 0; print; next }
        in_include && /^[[:space:]]*path[[:space:]]*=/ {
          #@ Extract the path value
          gsub(/^[[:space:]]*path[[:space:]]*=[[:space:]]*/, "")
          gsub(/[[:space:]]*$/, "")
          #@ Skip if it points to main.gitconfig
          if ($0 !~ /\/main\.gitconfig$/) {
            print "\tpath = " $0
          }
          next
        }
        { print }
      ' "${gitconfig_path}"

      #@ Add the include section if it doesn't exist, or append to existing one
      if ! grep -q "^\[include\]" "${gitconfig_path}"; then
        printf "[include]\n"
      fi

      #@ Add the current DOTS path as the last include
      printf "\tpath = %s\n" "${main_gitconfig_path}"

    } >"${temp_file}"

    #@ Replace the original file with the processed version
    if mv "${temp_file}" "${gitconfig_path}"; then
      _pout --info "Successfully updated git configuration"
      _pout --debug "Added include path: ${main_gitconfig_path}"
    else
      _pout --error "Failed to update git configuration"
      rm -f "${temp_file}"
      return 1
    fi
  }

  main
}

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
#DOC   findinit_dots \
#DOC      --name "dotfiles" \
#DOC      --home "/d/Projects/GitHub/CC" \
#DOC      --home "/cygdrive/d/Projects/GitHub/CC" \
#DOC      --name ".dots"
findinit_dots() {
  main() {
    trap 'cleanup' EXIT HUP INT TERM
    set_defaults
    parse_arguments "$@"
    execute_process
  }

  #DOC Initializes default configuration values for the script.
  #DOC
  #DOC - Sets the function name to "findinit_dots".
  #DOC - Configures the delimiter used for separating values in lists.
  #DOC - Preserves the original IFS (Internal Field Separator) and sets a custom
  #DOC   delimiter to use within the script.
  #DOC - Defines the default verbosity level as "info".
  #DOC - Sets the default configuration file name to ".dotsrc" if not already defined.
  #DOC - Establishes potential home directories and directory names for searching.
  set_defaults() {

    #DOC Restore shell state to pre-function invocation.
    cleanup() {
      IFS="${ifs}"
      unset names homes delimiter verbosity ctx fn_name rc
    } && cleanup

    #@ Initialize integral variables
    : "${fn_name:="findinit_dots"}"
    : "${rc:=".dotsrc"}"
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
    : "${verbosity:="info"}"
    : "${ifs:="${IFS}"}"
    : "${delimiter:="$(printf "\037")"}"
    IFS="${delimiter}"
  }

  #DOC Parse command-line arguments to set configuration options.
  #DOC
  #DOC Recognized options:
  #DOC -h, --help            Display usage information and exit.
  #DOC -d, --debug, --dry-run
  #DOC                      Enable debug verbosity level.
  #DOC --name, --dir DIRNAME
  #DOC                      Add DIRNAME to the list of directory names.
  #DOC --home, --parent DIR Add DIR to the list of parent directories.
  #DOC --rc RCFILE          Specify the RC file to look for.
  #DOC
  #DOC Arguments without options are added to the list of parent directories.
  #DOC Returns 0 on success, 1 on errors such as missing arguments.

  parse_arguments() {
    #@ Set defaults
    homes="" names=""

    #@ Parse Arguments
    while [ $# -gt 0 ]; do
      case "$1" in
      -h | --help)
        printf 'Usage: %s [--name DIRNAME] [--home DIR] [-d|--debug]\n' "${scr_name}"
        return 0
        ;;
      -d | --debug | --dry-run)
        verbosity=4
        ;;
      --name | --dir)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        names="${names:+${names}${delimiter}}$2"
        shift
        ;;
      --home | --parent)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        homes="${homes:+${homes}${delimiter}}$2"
        shift
        ;;
      --rc)
        if [ $# -lt 2 ]; then
          _pout --error "Missing argument: " "$1"
          return 1
        fi
        rc="$2"
        shift
        ;;
      *)
        homes="${homes:+${homes}${delimiter}}$1"
        ;;
      esac
      shift
    done
  }

  #DOC Locate the first of the specified directories that contain a ".dotsrc" at the top level
  #DOC
  #DOC @param {string} [rc=".dotsrc"] The filename of the file to search for
  #DOC @param {string} [homes] A colon-separated list of directories to search
  #DOC @param {string} [names] A colon-separated list of directory names to search
  #DOC
  #DOC @returns {none} Sets the global variables "DOTS", "DOTS_RC" and "RC"
  execute_process() {
    #@ Set defaults
    homes="$(
      printf "%s\n" "${homes:-"${possible_homes}"}" |
        tr '\n' "${delimiter}"
    )"
    names="$(
      printf "%s\n" "${names:-"${possible_names}"}" |
        tr '\n' "${delimiter}"
    )"
    p=0

    #@ Loop through the specified parent directories
    for parent in ${homes}; do
      [ -d "${parent}" ] || continue
      p="$((p + 1))"
      _pout --trace "${p}: ${parent}"

      #@ Loop through the specified directory names appended to the parent
      d=0
      for dir in ${names}; do
        dots="${parent}/${dir}"
        [ -d "${dots}" ] || continue
        d="$((d + 1))"
        _pout --trace "${d}: ${dots}"

        #@ Use find to locate the first ".dotsrc" in the specified directory
        DOTS_RC=$(
          find "${dots}" \
            -maxdepth 1 \
            -type f -name "${rc}" \
            -print -quit
        )
        if [ -f "${DOTS_RC:-}" ]; then
          DOTS="$(dirname "${DOTS_RC:-}")"
          RC="$(basename "${DOTS_RC:-}")"
          break 2
        fi

      done
    done

    #@ Print debug information
    _pout --debug "RC: " "${RC}"
    _pout --debug "DOTS: " "${DOTS}"
    _pout --debug "DOTS_RC: " "${DOTS_RC}"

    if [ -f "${DOTS_RC:-}" ]; then
      export DOTS DOTS_RC RC
      # shellcheck disable=SC1090   #? Dynamic sourcing of user dotfiles
      . "${DOTS_RC}"

      #@ Update git configuration after DOTS is set
      update_gitconfig
    else
      _pout --debug "Unable to locate ${rc}"
      return 1
    fi
  }

  main "$@"
}

findinit_dots "${@:-}"
