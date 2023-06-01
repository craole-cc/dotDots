#! /bin/sh

#==================================================
#
# EXA
# /constant/app_exa
#
#==================================================

# _________________________________ DOCUMENTATION<|

# https://the.exa.website/
#
# Options
# --colour => auto; always; never
# --time-style => iso; long-iso; full-iso

# _______________________________________ EXPORT<|

case "$sys_INFO" in
*Linux*) ;;
*) return ;;
esac

#> Install <#
weHave exa || Install exa

#> Verify Instalation <#
weHave exa || return
"$NeedForSpeed" || weHave --report version exa >>"$DOTS_loaded_apps"
