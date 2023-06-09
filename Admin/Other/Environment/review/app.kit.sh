#! /bin/sh

#==================================================
#
# PATH TOOLKIT
# /function/envman.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _______________________________________ OPTIONS<|

appy() {
    app="$*"
    if [ -z "$app" ]; then
        echo "Method --> appCheck <APP>"
    else
        if ! [ -x "$(command -v "$app")" ]; then
            Installed=false
            echo Error: "$app" is not installed. >&2
            exit 1
        else
            Installed=true
            echo "$app" is available 'for' use from "$(command -v "$app")"
        fi
    fi
}

appCheck() (
    [ -z "$*" ] &&
        echo "Method --> Exists <APP>"

    for app in "$@"; do
        if command -v "$app" >/dev/null 2>&1; then
            Installed=true
            echo "$app" '→|' Found at "$(command -v "$app")"
        else
            unset Installed
            echo "$app" '→|' Not Found
        fi
    done
)
appLocation() {
    for app in "$@"; do
        if command -v "$app" >/dev/null 2>&1; then
            Installed=true
            echo "$app" '|>' "$(command -v "$app")"
        else
            unset Installed
            echo "$app" '<|'
        fi
    done
}

appRequired() {
    # for app in "$@"; do
        app=$1
        appCheck "$app"
        if ! $Installed; then
            echo Required '-->' "$app"
        else
            echo Installed '-->' "$app"
        fi
    # done
}

appDependencies() {
    for app in "$@"; do
        if Required "$app"; then
            printf '\n%s\n' "Dependencies:"
            expac --timefmt='%Y-%m-%d %T' '%n |> %o' |
                sort |
                grep -q "$app"
            if [ $? = 0 ]; then
                echo "$app" is installed independently
            fi
        else
            printf '\n%s\n' "Installed: $Installed"
            echo "$app" '<|'
        fi
    done
}
# _________________________________________ ALIAS<|

# __________________________________________ EXEC<|
