#! /bin/sh

#==================================================
#
# STARSHIP
# CLI/bin/environment/app/starship.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

DIR="${DOTS_DOWN:?}/speedtest-linux"
SPEEDTEST_APPS="
$DIR/speedtest-linux/speedtest
$DIR/fast.com/fast_com.py
$DIR/speedtest-linux/fasttest
"

# echo "Welcome To Linuxhint" | tr [:space:] '\n'
# echo "$APPS" | tr -s '\n' '|' -s '^|' 'X'
# echo "$APPS" | sed '/^$/d'
# echo "$APPS" | sed -r '/^[[:space:]]*$/d'
# echo "$APPS" | sd '\n' '|' | sed -e 's/^|//' -e 's/||//g'
# for app in $APPS; do
#     if weHave "$(basename "$app")"; then

#     app=$(echo "$(basename "$app")" | tr "[:upper:]" "[:lower:]" )
#     echo "$app"
#         # Establish Link in BIN
#         # ln "$app" "$DOTbin" \
#             # --symbolic \
#             # --force
#         # --verbose
#     fi
# done

# app1=
if weHave speedtest; then

    alias speedtest='speedtest --simple'
fi

__fasttest__() {
    app=fasttest
    if weHave "$app"; then
        echo "$app"
    fi
}

# app=fasttest
# if weHave "$app"; then
#     Fast() {
#         # $app --simple
#         echo "$app"
#     }
# fi

# # Aliases
# # for app in $(basename "$APPS"); do
# app=$(basename "$APPS")
# case "$app" in
# fasttest)
#     Fast() {
#         # $app --simple
#         echo "$app"
#     }
#     ;;
# speedtest)
#     Speed() {
#         # $app --simple
#         echo "$app"
#     }
#     alias speedy="$app --simple"
#     ;;
# *) echo "$app not found" ;;
# esac
# done
unset APPS
