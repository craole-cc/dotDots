#!/bin/sh
debug=1
main() {
  set -eu
  parse_arguments "$@"
  validate_git
  pull_updates

  # shellcheck disable=SC2310
  get_status || return 0

  add_changes
  commit_changes
  push_changes

  echo pop
  # post_local_updates
}

parse_arguments() {
  #@ Initialize defaults
  delimiter=" "
  msg=""
  verbose=""

  #@ Parse arguments
  while [ $# -gt 0 ]; do
    case "${1}" in
      -d | --verbose)
        verbose=true
        ;;
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

validate_git() {
  #@ Check if the git command is available
  command -v git > /dev/null 2>&1 || {
    printf "%s\n" "The git command is not available." >&2
    return 1
  }

  #@ Check if the current directory is a git repository
  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    printf "%s\n" "The current directory is not part of a git repository." >&2
    return 1
  }

  #@ Print debug information
  [ -n "${debug}" ] && printf "%s\n" "DEBUG: Validated git"
}

pull_updates() {
  #@ Capture the output of the pull command
  pull_output=$(git pull --autostash 2> /dev/null)

  #@ Check if the pull command was successful
  [ -n "${pull_output:-}" ] || {
    printf "%s\n%s\n" \
      "Error pulling from remote repository." \
      "${pull_output}" >&2
    return 1
  }

  #@ Ignore the message if the repository is up to date
  case "${pull_output:-}" in "Already up to date.") ;;
  *) printf "%s\n" "${pull_output}" ;;
  esac

  #@ Print debug information
  [ -n "${debug}" ] && printf "%s\n" "DEBUG: Got remote updates"
}

get_status() {
  #@ Skip if there are no change or display the current status
  if git status --porcelain > /dev/null 2>&1; then
    git status --short
    return 0
  else
    return 1
  fi
}

add_changes() {
  #@ Define the command with options
  cmd="git add"
  cmd="${cmd} --all"
  [ -n "${debug}" ] && cmd="${cmd} --dry-run"

  #@ Execute the command, returning an error if it fails
  eval "${cmd}" > /dev/null 2>&1 || {
    printf \
      "Encountered an error while executing '%s'\n" \
      "${cmd}" >&2
    eval "${cmd}"
  }

  #@ Print debug information
  printf "DEBUG: Added changes to the staging area\n"
}

commit_changes() {
  #@ Define the commit message
  _msg="$(git log -1 --pretty=%B 2> /dev/null | tr -d '\n')"
  _msg="${last_msg:-"Initial commit"}"

  [ -z "${msg}" ] && {
    printf "Enter a commit message [Default: %s ]: " "${_msg}"
    read -r msg
  }
  _msg="${msg:-"${_msg}"}"

  #@ Commit the changes
  _cmd="$(git commit --message "${_msg}")"
  [ -n "${debug}" ] && _cmd="${_cmd} --dry-run"

  #@ Execute the command, returning an error if it fails
  eval "${_cmd}" > /dev/null 2>&1 || {
    printf "Encountered an error while executing '%s'\n" "${_cmd}" >&2
    eval "${_cmd}"
  }
  
  #@ Print debug information
    printf "DEBUG: Committed changes\n"
}

post_changes() {
  #@ Update the remote repository
  push_args="--recurse-submodules=check"
  [ -n "${verbose:-}" ] || push_args="${push_args} --quiet"
  eval git push "${push_args:-}" 2> /dev/null
}

main "$@"
