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

case $sys_TYPE in
Windows) return 0 ;;
Linux) ;;
esac

#> Install <#
if ! weHave rg; then
	if weHave paru; then
		Pin ripgrep
	elif weHave dnf; then
		sudo dnf ripgrep -y
	elif weHave choco; then
		cup ripgrep -y
	elif weHave winget; then
		winget install ripgrep
	else
		CargoInstall ripgrep
	fi
fi

#> Verify Instalation <#
weHave rg || return
ver rg >>"$DOTS_loaded_apps"

#> Activate Aliases <#
