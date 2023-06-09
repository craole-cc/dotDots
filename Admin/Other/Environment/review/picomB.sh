#! /bin/sh
# shellcheck disable=SC2154
_picom_DOTS="${dotTOOL:?}/picom"
_picom_CFG_default="$XDG_CONFIG_HOME/picom/picom.conf"
_picom_CFG="$_picom_DOTS/picom.conf"

#> Install <#
if ! weHave picom; then
    OS=$(mango --lower "$sys_NAME")
    case $OS in
    *arch*) Pin picom ;;
    *) ;;
    esac
    # if weHave paru; then
    #     Pin picom
    # fi
fi

#> Verify Instalation <#
weHave picom || return
"$NeedForSpeed" || weHave --report version picom >>"$DOTS_loaded_apps"

# ________________________________________ EXPORT<|

#* Activate Aliases *#
Picom() { picom --config "$_picom_CFG"; }
