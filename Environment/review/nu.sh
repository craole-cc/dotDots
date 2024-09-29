#! /bin/sh

#==================================================
# NU
#==================================================

# _________________________________ DOCUMENTATION<|
# https://github.com/nushell/nushell/
# _________________________________________ LOCAL<|

DIR="${DOTconf:?}/alacritty"
WIN="$WIN_APPDATA/alacritty"
CFG="$DIR/alacritty.yml"
nuAPPS="nu --features=extra"

cargoInstall "$APPS"

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

# ______________________________________ EXTERNAL<|

unset APPS