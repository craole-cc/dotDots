#!/bin/sh

main() {
    set -eu
    parse_arguments "$@"
    update_repo
}

parse_arguments() {
    #@ Set defaults
    delimiter=" "
    msg=""

    #@ Parse arguments
    while [ $# -gt 0 ]; do
        case "${1}" in
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

update_repo() {
    #@ Update the local repository
    pull_output=$(git pull --quiet --autostash 2>/dev/null)
    pull_ignore_msg="Already up to date."
    case "$pull_output" in *"$pull_ignore_msg"*) ;;
    *) printf "%s\n" "$pull_output" ;;
    esac

    #@ Skip if there are no changes
    status_output=$(git status --porcelain 2>/dev/null)
    [ -z "${status_output}" ] && return 0

    #@ Display the current status
    git status --short

    #@ Stage all changes
    git add --all

    #@ Commit the changes with the provided message
    last_msg="$(git log -1 --pretty=%B 2>/dev/null)"
    default_msg="${last_msg:-"General update"}"
    [ -z "${msg}" ] &&
        printf "Enter a commit message [Default: %s ]: " "${default_msg}" &&
        read -r msg &&
        git commit --message "${msg:-"$default_msg"}"

    #@ Update the remote repository
    push_output="$(git push --recurse-submodules=check 2>&1)"

    # Define the patterns to filter out
    filter_patterns=""
    filter_patterns="$filter_patterns|Enumerating objects:"
    filter_patterns="$filter_patterns|Counting objects:"
    filter_patterns="$filter_patterns|Delta compression"
    filter_patterns="$filter_patterns|Compressing objects:"
    filter_patterns="$filter_patterns|Writing objects:"
    filter_patterns="$filter_patterns|Total"
    filter_patterns="$filter_patterns|remote: Resolving deltas:"
    filter_patterns="$filter_patterns|To https:\/\/github\.com"
    
    echo "Patterns to filter: ${filter_patterns}"
    # #@ Check for errors
    # if printf "%s" "$push_output" | grep -iq "error"; then
    #     printf "%s" "$push_output"
    # else
    #     # Filter out the unwanted lines
    #     filtered_output=$(printf "%s" "$push_output" | grep -vE "$filter_patterns")
    #     printf "%s" "$filtered_output"
    # fi
}

main "$@"
