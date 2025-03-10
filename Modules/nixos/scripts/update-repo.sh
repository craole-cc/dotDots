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
         git push --recurse-submodules=check |
             tee /dev/stderr | 
             sed -e '/^Enumerating objects:/d' \
                 -e '/^Counting objects:/d' \
                 -e '/^Delta compression/d' \
                 -e '/^Compressing objects:/d' \
                 -e '/^Writing objects:/d' \
                 -e '/^Total/d' \
                 -e '/^remote: Resolving deltas:/d' \
                 -e '/^To https:\/\/github\.com/d' \
                 -e '/^ * \[[a-z0-9]* [a-f0-9]*\]/d'
        
        # push_output="$(git push --recurse-submodules=check 2>&1)"
        
        # #@ Check for errors
        # if printf "%s" "$push_output" | grep -q "error\|fatal"; then
        #     printf "%s\n" "$push_output"
        # else
        #     #@ Filter out common git progress messages using sed
        #     filtered_output=$(printf "%s" "$push_output" | 
        #         sed -e '/^Enumerating objects:/d' \
        #             -e '/^Counting objects:/d' \
        #             -e '/^Delta compression/d' \
        #             -e '/^Compressing objects:/d' \
        #             -e '/^Writing objects:/d' \
        #             -e '/^Total/d' \
        #             -e '/^remote: Resolving deltas:/d' \
        #             -e '/^To https:\/\/github\.com/d')
        #     if [ -n "$filtered_output" ]; then
        #         printf "%s\n" "$filtered_output"
        #     fi
        # fi
}

main "$@"
