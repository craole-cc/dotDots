#!/bin/sh
# shellcheck disable=SC2034,SC1090

#==================================================
# HASKELL
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

GHCup_ENV=
GHCup_ENV="$DOTS_TOOL/utilities/ghcup/env"


# _________________________________________ TOOLS<|


# Load Config
[ -f "$GHCup_ENV" ] && . "$GHCup_ENV"

installGHCup() {
    case "${sys_INFO:-$(uname --all)}" in
    *Linux*) curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh ;;
    *) ;;
    esac
}

CabalInstall() {
    if ! weHave cabal; then
        installGHCup
    else
        for app in "$@"; do
            if ! weHave "$app"; then
                if weHave cabal-install; then
                    cargo binstall "$app"
                else
                    cargo install "$app"
                fi
            else
                weHave --verbose "$app"
            fi
        done
    fi
    unset app
}

#* Verify Instalation *#
weHave ghcup || installGHCup
weHave ghcup || return

# shellcheck disable=SC2154
{
    weHave --report version ghcup
    weHave --report version cabal
} >>"$DOTS_loaded_apps"

alias cabin='CargoInstall'