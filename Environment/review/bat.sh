#!/bin/sh
# shellcheck disable=SC2034

#==================================================
#
# BAT
# /function/envman.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ ALIAS<|

#> Verify Instalation <#
weHave bat || return
"$NeedForSpeed" || weHave --report version bat >>"$DOTS_loaded_apps"

# BAT() {
# 	bat \
# 		--force-colorization \
# 		"$@"
# }
# bat \
# 	--color=always \
# 	--style=header,numbers \
# 	--theme="TwoDark"
# --force-colorization
BAT_THEME="TwoDark"
BAT_STYLE="rule,numbers,changes"

# alias cat='bat --paging=never'
# alias bat="BAT"
