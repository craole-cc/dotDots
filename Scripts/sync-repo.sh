#!/bin/sh

main() {
  #| Initialize the script
  set_defaults
  parse_arguments "$@"
  set_operation_mode

  #| Perform Passive Actions
  validate_git
  create_cmd_output_file
  pull_updates
  get_status

  #| Execute Changes
  update_index
  commit_changes
  push_changes
}

set_defaults() {
  #@ Initialize defaults variables
  delimiter=" "
  msg=""
  nothing_to_commit=""
  error_encountered=""

  #@ Set the verbosity levels
  VERBOSITY_LEVEL_QUIET=0
  VERBOSITY_LEVEL_ERROR=1
  VERBOSITY_LEVEL_WARN=2
  VERBOSITY_LEVEL_INFO=3
  VERBOSITY_LEVEL_DEBUG=4
  VERBOSITY_LEVEL_TRACE=5

  #@ Set the default verbosity level
  VERBOSITY_LEVEL="${VERBOSITY_LEVEL_INFO}"
}

set_operation_mode() {
  #@ Enable strict mode
  set -eu

  #@ Enable trace, if requested
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}") set -x ;;
    # "${VERBOSITY_LEVEL_DEBUG}") set -v ;;
    *) ;;
  esac
}

parse_arguments() {
  while [ $# -ge 1 ]; do
    case "${1}" in
      -t | --trace) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_TRACE}" ;;
      -V | --verbose) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_INFO}" ;;
      -d | --debug | --dry-run) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_DEBUG}" ;;
      --info) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_INFO}" ;;
      --warn*) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_WARN}" ;;
      --error) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_ERROR}" ;;
      -q | --quiet) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_QUIET}" ;;
      -m | --message)
        msg="${2}"
        shift
        ;;
      *)
        msg="${msg}${msg:+${delimiter}}${1}"
        ;;
    esac
    shift
  done
}

pout() {
  #@ Initialize the output variables
  pout_tag=""
  pout_msg=""
  case_mod=""

  # Define the cleanup operation to perform on exit
  pout__cleanup() {
    unset pout_tag pout_msg case_mod
  }
  trap 'pout__cleanup' EXIT INT TERM HUP

  #@ Parse the arguments
  while [ "$#" -ge 1 ]; do
    case "${1}" in
      --trace)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_TRACE}" ] || return 0
        pout_tag="<\ TRACE />"
        ;;
      --debug)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_DEBUG}" ] || return 0
        pout_tag="<\ DEBUG />"
        ;;
      --info)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_INFO}" ] || return 0
        pout_tag="<\  INFO />"
        ;;
      --warn*)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_WARN}" ] || return 0
        pout_tag="<\  WARN />"
        ;;
      --err*)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_ERROR}" ] || return 0
        pout_tag="<\ ERROR />"
        ;;
      --upper)
        case_mod="upper"
        ;;
      --lower)
        case_mod="lower"
        ;;
      --sentence)
        case_mod="sentence"
        ;;
      --title)
        case_mod="title"
        ;;
      *)
        case "${1}" in
          '') ;;
          *) pout_msg="${pout_msg}${pout_msg:+${delimiter}}${1}" ;;
        esac
        ;;
    esac
    shift
  done

  #@ Return early if no message to print (without a status)
  if [ -z "${pout_msg}" ]; then
    return
  fi

  #@ Modify case, if requested
  case "${case_mod}" in
    upper) pout_msg="$(printf "%s" "${pout_msg}" | tr '[:lower:]' '[:upper:]')" ;;
    lower) pout_msg="$(printf "%s" "${pout_msg}" | tr '[:upper:]' '[:lower:]')" ;;
    sentence)
      first_char=$(printf "%s" "${pout_msg}" | cut -c1 | tr '[:lower:]' '[:upper:]')
      rest_of_string=$(printf "%s" "${pout_msg}" | cut -c2- | tr '[:upper:]' '[:lower:]')
      pout_msg="${first_char}${rest_of_string}."
      ;;
    title)
      pout_msg="$(pout --lower "${pout_msg}")"
      words=$(printf "%s" "${pout_msg}")
      title_cased=""

      for word in ${words}; do
        first_char=$(printf "%s" "${word}" | cut -c1)
        rest_of_word=$(printf "%s" "${word}" | cut -c2-)
        first_char_upper="$(pout --upper "${first_char}")"

        # Only add space if not the first word
        if [ -n "${title_cased}" ]; then
          title_cased="${title_cased} "
        fi
        title_cased="${title_cased}${first_char_upper}${rest_of_word}"
      done

      # Define the message as the whole title-cased string
      pout_msg="${title_cased}"
      ;;
    *) ;;
  esac

  #@ Print the tag if it exists, followed bu a space
  [ -n "${pout_tag}" ] && printf "%s " "${pout_tag}"

  #@ Strip leading and trailing whitespace
  pout_msg="${pout_msg#"${pout_msg%%[![:space:]]*}"}"   #? Remove leading whitespace
  pout_msg="${pout_msg%"${pout_msg##*[![:space:]]}"}"   #? Remove trailing whitespace

  #@ Print the output message
  printf "%s\n" "${pout_msg}"
}

validate_git() {
  #@ Check if the git command is available
  GIT_CMD=$(command -v git)
  if [ -n "${GIT_CMD}" ]; then
    pout --debug "Using git command:" "${GIT_CMD}"
  else
    pout --error "The git command is not available."
    return 1
  fi

  #@ Attempt to retrieve the path to the project root directory
  git_dir="$(eval "${GIT_CMD} rev-parse --show-toplevel" 2> /dev/null)" || {
    pout --error "This directory is not part of a git repository."
    pout --warn "Please navigate to a valid git repository and try again."
    return 1
  }

  if [ -d "${git_dir}" ]; then #?: Is -d enough to validate access?
    pout --debug "Using git directory:" "${git_dir}"
  else
    pout --error "Git directory exists but cannot be accessed: ${git_dir}"
    return 1
  fi
}

create_cmd_output_file() {
  #@ Create a temporary file if possible
  CMD_OUTPUT=$(mktemp 2> /dev/null || mktemp -t "githelper.XXXXXX")
  if [ -z "${CMD_OUTPUT}" ] || [ ! -f "${CMD_OUTPUT}" ]; then
    pout --error "Failed to create temporary file"
    return 1
  else
    pout --debug "Created temporary file: ${CMD_OUTPUT}"
  fi

  #@ Set up cleanup trap to remove the temp file on exit
  tmp__cleanup() {
    rm -f "${CMD_OUTPUT:-}"
    unset CMD_OUTPUT
  }
  trap 'tmp__cleanup' EXIT INT TERM HUP

  #@ Define the redirect command
  execute_command() {
    #@ Set up cleanup trap to remove the temp file on exit
    cmd__cleanup() {
      unset CMD CMD_TAG CMD_MSG CMD_STATUS CMD_RESULT CMD_LABEL HEADER_ONLY NO_HEADER
    }
    trap 'cmd__cleanup' EXIT INT TERM HUP

    #@ Initialize the command variables
    CMD="" CMD_TAG="true" CMD_MSG="" CMD_STATUS="" CMD_RESULT="" CMD_LABEL="" header_print=""

    #@ Parse arguments
    while [ $# -ge 1 ]; do
      case "${1}" in
        --cmd | --command)
          CMD="${2}"
          ;;
        --header* | --no-exec)
          header_print=only
          ;;
        --no-header | --no-exec)
          header_print=off
          ;;
        --success) CMD_SUCCESS="${2}" ;;
        --failure) CMD_FAILURE="${2}" ;;
        --error | --info | --warn | --debug | quiet | --trace)
          CMD_TAG="${1}"
          CMD_MSG="${2}"
          ;;
        --label)
          CMD_LABEL="${2}"
          ;;
        --no-tag)
          CMD_TAG=""
          ;;
        *) ;;
      esac
      shift
    done

    #@ Ensure the arguments are valid
    [ -n "${CMD}" ] || {
      pout --error "No command provided"
      return 1
    }

    #@ Print the header information of the process
    CMD_LABEL="$(pout --title "${CMD_LABEL}")"

    case "${header_print}" in
      no | off) ;;
      *)
        pout --info "===" "${CMD_LABEL}" "==="
        pout --debug "Command:" "${CMD}"
        ;;
    esac

    if [ "${header_print}" = "only" ]; then
      return 0
    fi

    if [ -n "${CMD_TAG}" ]; then
      #@ Capturing the status command through redirection
      if eval "${CMD}" > "${CMD_OUTPUT}" 2>&1; then
        CMD_STATUS="$?"
      else
        CMD_STATUS="$?"
      fi
    else
      #@ Execute and return the output directly
      eval "${CMD}"
      return "$?"
    fi

    #@ Store the result of the command in a reusable variable
    CMD_RESULT=$(cat "${CMD_OUTPUT}")

    #@ Update the status message to account for debug mode
    case "${VERBOSITY_LEVEL}" in
      "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}")
        msg_debug="would have"
        ;;
      *) msg_debug="" ;;
    esac
    CMD_SUCCESS="$(pout --sentence "${msg_debug}" "${CMD_SUCCESS}")"
    CMD_FAILURE="$(pout --sentence "${msg_debug}" "${CMD_FAILURE}")"

    #@ Tag and print the output
    if [ "${CMD_STATUS}" -eq 0 ]; then

      #@ Skip it "Already up to date"
      case "${CMD_RESULT}" in
        *"Already up to date"*) pout --info "The local repo already in sync with the remote" ;;
        *)
          #@ Tag each line of output seperatly
          while IFS= read -r line; do
            case "${line}" in
              '') ;;
              *) pout --info "${line:-}" ;;
            esac
          done < "${CMD_OUTPUT}"

          #@ Print the status message
          pout --info "${CMD_SUCCESS}"
          ;;
      esac
    else
      #@ Tag each line of output seperatly
      while IFS= read -r line; do
        case "${line}" in
          '') ;;
          *) pout --error "${line:-}" ;;
        esac
      done < "${CMD_OUTPUT}"

      #@ Print the status message
      pout --error "${CMD_FAILURE}" "[Exit Code: ${CMD_STATUS}]"
    fi

    #@ Exit the function with the status from the command
    return "${CMD_STATUS}"
  }
}

pull_updates() {
  #@ Define command information
  cmd="${GIT_CMD} pull --autostash"
  cmd_label="Remote Update Retrieval"
  msg_success="Integrated remote changes with the local branch"
  msg_failure="Failed to pull updates from remote repository"

  #@ Define the cleanup function
  cleanup() {
    unset cmd cmd_label msg_success msg_failure msg_debug
  }
  trap 'cleanup' EXIT INT TERM HUP

  #@ Update the command based on verbosity level
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}")
      cmd="${cmd} --dry-run"
      ;;
    "${VERBOSITY_LEVEL_INFO}")
      cmd="${cmd} --verbose"
      ;;
    "${VERBOSITY_LEVEL_QUIET}")
      cmd="${cmd} --quiet"
      ;;
    *) ;;
  esac

  #@ Execute the command with necessay options
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --success "${msg_success}" \
    --failure "${msg_failure}"
}

get_status() {
  #@ Check if there are any changes to commit
  _changes="$(${GIT_CMD} status --porcelain 2> /dev/null)"

  #@ Update the nothing_to_commit flag if there are no changes
  [ -n "${_changes}" ] || {
    pout --info "Nothing to commit, working directory clean"
    nothing_to_commit=true
    return 0
  }

  #@ Define command information
  cmd="${GIT_CMD} status"
  cmd_label="Working Tree Status"
  msg_success="Retrieved the status of the repository"
  msg_failure="Failed to retrieve the status of the repositroy"

  #@ Define the cleanup function
  cleanup() {
    unset cmd cmd_label msg_success msg_failure msg_debug _changes
  }
  trap 'cleanup' EXIT INT TERM HUP

  #@ Define the command
  cmd="${GIT_CMD} status"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_INFO}")
      cmd="${cmd} --verbose"
      ;;
    "${VERBOSITY_LEVEL_DEBUG}")
      cmd="${cmd} --short"
      ;;
    "${VERBOSITY_LEVEL_WARN}" | "${VERBOSITY_LEVEL_ERROR}" | "${VERBOSITY_LEVEL_QUIET}")
      cmd="${cmd} >/dev/null 2>&1"
      ;;
    *) ;;
  esac

  #@ Execute the command with necessay options
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --success "${msg_success}" \
    --failure "${msg_failure}" \
    --no-tag
}

update_index() {
  #@ Define command information
  cmd="${GIT_CMD} add --all"
  cmd_label="index update"
  msg_success="updated the index with the changed/untracked files"
  msg_failure="failed to update the index with the changed/untracked files"

  #@ Define the cleanup function
  cleanup() {
    unset cmd cmd_label msg_success msg_failure msg_debug
  }
  trap 'cleanup' EXIT INT TERM HUP

  #@ Skip if there are no changes
  [ -n "${nothing_to_commit:-}" ] && {
    msg_success="$(pout --sentence "Skipping" "${cmd_label}" "with nothing to commit")"
    pout --debug "${msg_success}"
    return 0
  }

  #@ Update the command based on verbosity level
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_INFO}")
      # cmd="${cmd} --verbose"
      ;;
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}")
      cmd="${cmd} --dry-run"
      ;;
    *) ;;
  esac

  #@ Execute the command with necessay options
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --success "${msg_success}" \
    --failure "${msg_failure}"
}

commit_changes() {
  #@ Define command information
  cmd="${GIT_CMD} commit --all"
  cmd_label="Logging Local Changes"
  msg_success="updated the index with the changed/untracked files"
  msg_failure="failed to update the index with the changed/untracked files"

  #@ Define the cleanup function
  cleanup() {
    unset cmd cmd_label msg_success msg_failure msg_last_commit msg_init_commit msg_commit
  }
  trap 'cleanup' EXIT INT TERM HUP

  #@ Skip if there are no changes
  [ -n "${nothing_to_commit:-}" ] && {
    msg_success="$(pout --sentence "Skipping" "${cmd_label}" "with nothing to commit")"
    pout --debug "${msg_success}"
    return 0
  }

  #@ Print the header only
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --header-only

  #@ Retrive the most recent commit message
  msg_last_commit="$(${GIT_CMD} log -1 --pretty=%B 2> /dev/null | tr -d '\n')"

  #@ Define the commit message with a default value
  msg_init_commit="Initial commit"

  #@ Prompt the user for an updated commit message, if not provided
  if [ -z "${msg:-}" ]; then
    pout --warn --sentence "You may provide a commit message below" \
      "or accept the default: '${msg_last_commit:-"${msg_init_commit}"}'"
    read -r msg
  fi

  #@ Define the commit message from the user input or default value
  msg_commit="${msg:-"${msg_init_commit}"}"

  #@ Update the command based on verbosity level
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_INFO}") cmd="${cmd} --verbose" ;;
    "${VERBOSITY_LEVEL_TRACE}") cmd="${cmd} --dry-run --long" ;;
    "${VERBOSITY_LEVEL_DEBUG}") cmd="${cmd} --dry-run --short" ;;
    "${VERBOSITY_LEVEL_QUIET}") cmd="${cmd} --quiet" ;;
    *) ;;
  esac
  cmd="${cmd} --message='${msg_commit}'"

  #@ Execute the command with necessay options
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --success "${msg_success}" \
    --failure "${msg_failure}" \
    --no-header
}

push_changes() {
  #@ Define command information
  cmd="${GIT_CMD} push --recurse-submodules=check --follow-tags"
  cmd_label="Update Remote"
  msg_success="updated the remote with the local changes"
  msg_failure="failed to the remote with the local changes"

  #@ Define the cleanup function
  cleanup() {
    unset cmd cmd_label msg_success msg_failure msg_debug
  }
  trap 'cleanup' EXIT INT TERM HUP

  #@ Skip if there are no changes
  [ -n "${nothing_to_commit:-}" ] && {
    msg_success="$(pout --sentence "Skipping" "${cmd_label}" "with nothing to commit")"
    pout --debug "${msg_success}"
    return 0
  }

  #@ Update the command based on verbosity level
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}")
      cmd="${cmd} --dry-run"
      ;;
    "${VERBOSITY_LEVEL_INFO}")
      cmd="${cmd} --verbose"
      ;;
    # "${VERBOSITY_LEVEL_WARN}") ;; #TODO: Update to show only warnings
    # "${VERBOSITY_LEVEL_ERROR}") ;;   #TODO: Update to show only errors
    "${VERBOSITY_LEVEL_QUIET}")
      cmd="${cmd} --quiet"
      ;;
    *) ;;
  esac

  #@ Execute the command with necessay options
  execute_command \
    --label "${cmd_label}" \
    --command "${cmd}" \
    --success "${msg_success}" \
    --failure "${msg_failure}"
}

main "$@"
