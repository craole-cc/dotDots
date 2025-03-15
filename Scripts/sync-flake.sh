#!/bin/sh

main() {
    set -eu
    parse_arguments "$@"
    update_repo
    # update_flake
    update_repo
}

update_repo(){
    command -v sync-repo.sh && sync-repo.sh --quiet "Flake Update"
}

parse_arguments() {
    #@ Set defaults
    delimiter=" "
    args=""

    #@ Parse arguments
    while [ $# -gt 0 ]; do
        case "${1}" in
        -a | --arg*)
            args="${args}${args:+${delimiter}}${2}"
            shift
            ;;
        *)
            args="${args}${args:+${delimiter}}${1}"
            ;;
        esac
        shift
    done
}

update_flake() {
    #@ Proceed only if nix flake is available
    nix_flake="$(nix flake update --help 2>/dev/null)"
    [ -z "${nix_flake}" ] && {
        printf "Nix flake doesn't seem to be available\n"
        return 1
    }

    eval nix flake update "${args}"
    return 0
}

main "$@"
