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
    push_output="$(git push --recurse-submodules=check)"
    push_filtered_msg=$(
        printf "%s" "${push_output:-}" | 
        grep -vE '^(Enumerating objects:|Counting objects:|Delta compression using up to 16 threads|Compressing objects:|Writing objects:|Total|remote: Resolving deltas:|To https:\/\/github\.com\/craole-cc\/dotDots\.git|0d64b329\.\.ae1ae18f  main -> main)')
    # printf "%s\n" "$"${push_output##*$push_filtered_msg*}""
    [ -n "${push_filtered_msg}" ] && printf "%s\n" "${push_filtered_msg}"


main "$@"
