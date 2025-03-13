#!/bin/sh

main() {
  #| Initialize the script
  set_defaults
  parse_arguments "$@"
  set_operation_mode

  #| Execute the script
  create_cmd_output_file
  validate_git
  pull_updates
  get_status
  update_index

  commit_changes
  return #TODO: Remove this line after completing the subsequent functions
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
  VERBOSITY_LEVEL_WARNING=2
  VERBOSITY_LEVEL_INFO=3
  VERBOSITY_LEVEL_DEBUG=4
  VERBOSITY_LEVEL_TRACE=5

  #@ Set the default verbosity level
  VERBOSITY_LEVEL="${VERBOSITY_LEVEL_WARNING}"
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
      --warn*) VERBOSITY_LEVEL="${VERBOSITY_LEVEL_WARNING}" ;;
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

  #@ Parse the arguments
  while [ "$#" -ge 1 ]; do
    case "${1}" in
      --trace)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_TRACE}" ] || return
        pout_tag="<\ TRACE />"
        ;;
      --debug)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_DEBUG}" ] || return
        pout_tag="<\ DEBUG />"
        ;;
      --info)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_INFO}" ] || return
        pout_tag="<\  INFO />"
        ;;
      --warn*)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_WARNING}" ] || return
        pout_tag="<\  WARN />"
        ;;
      --err*)
        [ "${VERBOSITY_LEVEL}" -ge "${VERBOSITY_LEVEL_ERROR}" ] || return
        pout_tag="<\ ERROR />"
        ;;
      *)
        pout_msg="${pout_msg}${pout_msg:+${delimiter}}${1}"
        ;;
    esac
    shift
  done

  #@ Print the output
  printf "%s %s\n" "${pout_tag}" "${pout_msg}"

  #@ Clean up
  unset pout_tag pout_msg
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
  trap 'rm -f "${CMD_OUTPUT}"' EXIT INT TERM HUP

  # return 0 #? is this necessary? If we've reached here, the file should exist and we automatically return 0
}

validate_git() {
  #@ Check if the git command is available
  GIT_CMD=$(command -v git)
  if [ -n "${GIT_CMD}" ]; then
    pout --debug "Using git command:" "${GIT_CMD}"
    GIT_CMD_CLR="${GIT_CMD} --color=always"
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

pull_updates() {
  #@ Announce the pull operation
  pout --debug "Pulling updates from the remote repository..."

  #@ Define the pull command
  pull_cmd="${GIT_CMD} pull --autostash"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}") pull_cmd="${pull_cmd} --dry-run" ;;
    "${VERBOSITY_LEVEL_INFO}") pull_cmd="${pull_cmd} --verbose" ;;
    "${VERBOSITY_LEVEL_QUIET}") pull_cmd="${pull_cmd} --quiet" ;;
    *) ;;
  esac

  #@ Execute git pull and capture both output and exit status
  if ${pull_cmd} > "${CMD_OUTPUT}" 2>&1; then
    pull_status=$?
    pull_output=$(cat "${CMD_OUTPUT}")

    #@ Check if output contains "Already up to date"
    if grep -q "Already up to date" "${CMD_OUTPUT}"; then
      pout --info "There are no new updates to retrieve"
    else
      pout --info "Updates successfully retrieved"
      #@ Show the actual git output
      [ -n "${pull_output}" ] && pout --info "${pull_output}"
    fi
  else
    pull_status=$?
    pull_output=$(cat "${CMD_OUTPUT}")

    #@ Handle error case
    pout --error "Failed to pull updates from remote repository (Exit Code: ${pull_status})"
    pout --error "${pull_output}"
  fi

  #@ Clean up
  pout --debug "Pull operation completed"
  unset pull_cmd pull_status pull_output
  return 0
}

get_status() {
  #@ Check if there are any changes to commit
  _changes="$(${GIT_CMD} status --porcelain 2> /dev/null)"

  #@ Define the status command
  status_cmd="${GIT_CMD} status"
    case "${VERBOSITY_LEVEL}" in
        "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_INFO}") status_cmd="${status_cmd} --verbose" ;;
        "${VERBOSITY_LEVEL_DEBUG}") status_cmd="${status_cmd} --short" ;;
        "${VERBOSITY_LEVEL_WARN}" | "${VERBOSITY_LEVEL_ERROR}" | "${VERBOSITY_LEVEL_QUIET}") status_cmd="${status_cmd} >/dev/null 2>&1" ;;
        *) ;;
    esac
    
  if [ -z "${_changes}" ]; then
    pout --info "Nothing to commit, working directory clean"
    nothing_to_commit=true
  else
    #@ Show output line by line if present
    if [ -s "${CMD_OUTPUT}" ]; then
      pout --info "Git add output:"

      #@ Process each line of output with an appropriate tag
      while IFS= read -r line; do
        [ -n "${line}" ] && pout --info "${line}"
      done < "${CMD_OUTPUT}"
    else
      pout --debug "Files successfully added to staging area"
    fi
  fi

  #@ Unset temporary variables
  unset _changes
}

update_index() {
  #@ Announce the add operation and skip if there are no changes
  if [ -n "${nothing_to_commit:-}" ]; then
    pout --debug "Skipping index update as there's nothing to commit"
    return 0
  else
    pout --debug "Updating git index with changed/untracked files..."
  fi

  #@ Define the command with options
  add_cmd="${GIT_CMD} add --all"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_INFO}") add_cmd="${add_cmd} --interactive" ;;
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_DEBUG}") add_cmd="${add_cmd} --dry-run" ;;
    *) ;;
  esac

  #@ Execute the command and capture output
  if eval "${add_cmd}" > "${CMD_OUTPUT}" 2>&1; then
    add_status=$?

    #@ Show output line by line if present
    if [ -s "${CMD_OUTPUT}" ]; then
      pout --info "Git add output:"

      #@ Process each line of output with an appropriate tag
      while IFS= read -r line; do
        [ -n "${line}" ] && pout --info "${line}"
      done < "${CMD_OUTPUT}"
    else
      pout --debug "Files successfully added to staging area"
    fi
  else
    add_status=$?

    #@ Handle errors with each line appropriatly tagged
    pout --error "Failed to add changed/untracked files to the staging area (Exit Code: ${add_status})"
    while IFS= read -r line; do
      [ -n "${line}" ] && pout --error "${line}"
    done < "${CMD_OUTPUT}"

    return "${add_status}"
  fi

  #@ Print completion information
  pout --debug "Index update operation completed"
  unset add_cmd add_status
}

commit_changes() {
  #@ Announce the add operation and skip if there are no changes
  if [ -n "${nothing_to_commit:-}" ]; then
    pout --debug "Skipping commit as there's nothing to commit"
    return 0
  else
    pout --debug "Committing changes to repository..."
  fi

  #@ Retrive the most recent commit message
  last_commit_msg="$(${GIT_CMD} log -1 --pretty=%B 2> /dev/null | tr -d '\n')"

  #@ Define the commit message with a default value
  default_msg="${last_commit_msg:-"Initial commit"}"

  #@ Prompt the user for a commit message, if not provided
  if [ -z "${msg:-}" ]; then
    pout --warn \
      "You may provide a commit message below. (Default:" "${default_msg}" ")"
    read -r msg
  fi

  #@ Define the commit message from the user input or default value
  commit_msg="${msg:-"${default_msg}"}"

  #@ Define the commit command with options
  commit_cmd="${GIT_CMD} commit --all"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_INFO}") commit_cmd="${commit_cmd} --verbose" ;;
    "${VERBOSITY_LEVEL_TRACE}") commit_cmd="${commit_cmd} --dry-run --long" ;;
    "${VERBOSITY_LEVEL_DEBUG}") commit_cmd="${commit_cmd} --dry-run --short" ;;
    "${VERBOSITY_LEVEL_QUIET}") commit_cmd="${commit_cmd} --quiet" ;;
    *) ;;
  esac
  commit_cmd="${commit_cmd} --message='${commit_msg}'"

  #@ Execute the command and capture output
  if eval "${commit_cmd}" > "${CMD_OUTPUT}" 2>&1; then
    commit_status=$?

    #@ Show output line by line if present
    if [ -s "${CMD_OUTPUT}" ]; then
      pout --info "Git commit output:"

      #@ Process each line and print the output with an appropriate tag
      while IFS= read -r line; do
        #TODO: Retain color output for better readability
        [ -n "${line}" ] && pout --info "+" "${line}"
      done < "${CMD_OUTPUT}"
    else
      pout --info "Changes committed successfully with message: ${commit_msg}"
    fi
  else
    commit_status=$?

    #@ Handle errors with each line appropriatly tagged
    pout --error \
      "Failed to commit changes with message:" \
      "${commit_msg}" "(Exit Code: ${commit_status})"
    while IFS= read -r line; do
      #TODO: Retain color output for better readability
      [ -n "${line}" ] && pout --error "${line}"
    done < "${CMD_OUTPUT}"

    return "${commit_status}"
  fi

  #@ Print completion information
  pout --debug "Commit operation completed"
  unset commit_msg commit_cmd last_commit_msg default_msg commit_status
  return 0 #? is this necessary? If we've reached here, the file should exist and we automatically return 0
}

commit_changes_OLD() {
  #@ Retrive the most recent commit message
  last_commit_msg="$(git log -1 --pretty=%B 2> /dev/null | tr -d '\n')"

  #@ Define the commit message with a default value
  default_msg="${last_commit_msg:-"Initial commit"}"

  #@ Prompt the user for a commit message, if not provided
  [ -n "${msg:-}" ] || {
    pout --warn \
      "You may provide a commit message here. [Default: %s ]: " \
      "${default_msg}"
    read -r msg
  }

  #@ Define the commit message from the user input or default value
  commit_msg="${msg:-"${default_msg}"}"

  #@ Define the commit command with options
  commit_cmd="git commit --all"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_INFO}") commit_cmd="${commit_cmd} --verbose" ;;
    "${VERBOSITY_LEVEL_DEBUG}") commit_cmd="${commit_cmd} --dry-run --short" ;;
    "${VERBOSITY_LEVEL_QUIET}") commit_cmd="${commit_cmd} --quiet" ;;
    *) ;;
  esac
  commit_cmd="${commit_cmd} --message='${commit_msg}'"

  #@ Execute the command, returning an error if it fails
  commit_cmd_output="$(eval "${commit_cmd}" 2>&1)"
  [ -n "${commit_cmd_output}" ] && {
    pout --error \
      "Failed to commit changes with message: " \
      "${commit_msg}"
    pout --error "${commit_cmd_output}"
    return "$?"
  }

  #@ Print debug information
  pout --debug "Committed changes with message: " "${commit_msg}"

  #@ Unset temporary variables
  unset commit_msg commit_cmd last_commit_msg
}

push_changes() {
  #@ Define the push command
  push_cmd="git push --recurse-submodules=check"
  case "${VERBOSITY_LEVEL}" in
    "${VERBOSITY_LEVEL_TRACE}" | "${VERBOSITY_LEVEL_INFO}") push_cmd="${push_cmd} --verbose" ;;
    "${VERBOSITY_LEVEL_DEBUG}") push_cmd="${push_cmd} --dry-run" ;;
    # "${VERBOSITY_LEVEL_WARNING}") ;; #TODO: Update to show only warnings
    # "${VERBOSITY_LEVEL_ERROR}") ;;   #TODO: Update to show only errors
    "${VERBOSITY_LEVEL_QUIET}") push_cmd="${push_cmd} --quiet" ;;
    *) ;;
  esac

  #@ Execute the command, returning an error if it fails
  push_cmd_output="$(eval "${push_cmd}" 2>&1)"
  [ -n "${push_cmd_output}" ] && {
    pout --error "Failed to push the changes to the remote repository"
    pout --error "${push_cmd_output}"
  }

  #@ Print debug information
  pout --debug "Pushed changes to the remote repository"

  #@ Unset temporary variables
  unset push_cmd push_cmd_output
}

main "$@" --debug
