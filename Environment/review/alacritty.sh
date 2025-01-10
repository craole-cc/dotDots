#! /bin/sh
# alacrittyTUX="$XDG_CONFIG_HOME/alacritty"
# alacrittyWIN="$WIN_CONFIG_HOME/alacritty"
# alacritty_DOTS="$DOTS_APP/alacritty"
# alacrittyDATA="$WIN_APPDATA/alacritty"
# "$XDG_CONFIG_HOME/alacritty/alacritty.yml"

case "$sys_INFO" in
*Windows*)
    alacrittyCFG="$DOTS_APP/alacritty/win/alacritty.yml"
    ;;
*Linux*)
    alacrittyCFG="$DOTS_APP/alacritty/alacritty.yml"
    ;;
esac

#> Install <#
if ! weHave alacritty; then
    if weHave paru; then
        Pin alacritty
    elif weHave choco; then
        cup alacritty -y
    elif weHave winget; then
        winget install alacritty
    else
        CargoInstall alacritty
    fi
fi

#> Verify Instalation <#
weHave alacritty || return

# shellcheck disable=SC2154
weHave --report version alacritty >>"$DOTS_loaded_apps"

#> Establish Link in HOME
# case $sys_INFO in
# *Windows*)
#     if [ ! -L "$alacrittyWIN" ]; then
#         rm --recursive --force "$alacrittyWIN"
#         ln --symbolic --force "$alacrittyDOTS/win" "$alacrittyWIN"
#     fi
#     ;;
# *Linux*)
#     if [ ! -L "$alacrittyTUX" ]; then
#         rm --recursive --force "$alacrittyTUX"
#         ln --symbolic --force "$alacrittyDOTS/tux" "$alacrittyTUX"
#     fi
#     ;;

# *) ;;
# esac

# ________________________________________ EXPORT<|

#* Activate Aliases *#
alias ala='alacritty'
