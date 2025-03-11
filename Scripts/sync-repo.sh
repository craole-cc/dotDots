#!/bin/sh
debug=1

main() {
    set -eu
    parse_arguments "$@"
    validate_git
    pull_updates

    # shellcheck disable=SC2310
    get_status && {
        echo pop
        # add_changes
        # commit_changes
        # post_changes
    }

    # add_changes
    # commit_changes
    # push_changes
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
    command -v git >/dev/null 2>&1 || {
        printf "%s\n" "The git command is not available." >&2
        return 1
    }

    #@ Check if the current directory is a git repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        printf "%s\n" "The current directory is not part of a git repository." >&2
        return 1
    }

    #@ Print debug information
    [ -n "${debug}" ] && printf "%s\n" "DEBUG: Validated git"
}

pull_updates() {
    #@ Capture the output of the pull command
    _cmd=$(git pull --autostash 2>/dev/null)

    #@ Check if the pull command was successful
    [ -n "${_cmd:-}" ] || {
        printf "%s\n%s\n" \
            "Error pulling from remote repository." \
            "${_cmd}" >&2
        return 1
    }

    #@ Ignore the message if the repository is up to date
    case "${_cmd:-}" in "Already up to date.") ;;
    *) printf "%s\n" "${_cmd}" ;;
    esac

    #@ Print debug information
    [ -n "${debug}" ] && printf "%s\n" "DEBUG: Got remote updates"
}

get_status() {
    #@ Skip if there are no change
    git status --porcelain >/dev/null 2>&1 || return 1

    #@ Display the current status
    git status --short
}

add_changes() {
    #@ Define the command with options
    _cmd="git add"
    _cmd="${_cmd} --all"
    [ -n "${debug}" ] && _cmd="${_cmd} --dry-run"

    #@ Execute the command, returning an error if it fails
    eval "${_cmd}" >/dev/null 2>&1 || {
        printf \
            "Encountered an error while executing '%s'\n" \
            "${_cmd}" >&2
        eval "${_cmd}"
    }

    #@ Print debug information
    printf "DEBUG: Added changes to the staging area\n"
}

commit_changes() {
    #@ Define the commit message
    _msg="$(git log -1 --pretty=%B 2>/dev/null | tr -d '\n')"
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
    eval "${_cmd}" >/dev/null 2>&1 || {
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
    eval git push "${push_args:-}" 2>/dev/null
}

main "$@"
