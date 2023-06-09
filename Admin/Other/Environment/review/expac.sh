#! /bin/sh

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/falconindy/expac

# _________________________________________ LOCAL<|

#> Verify Instalation <#
weHave expac || return

#> Install <#
if ! weHave expac; then
	if weHave paru; then
		Pin expac
	elif weHave pacman; then
		pacman -S expac
	fi
fi

#> Verify Instalation <#
if weHave expac; then
	ver expac >>"$DOTS_loaded_apps"
else
	return
fi

# _______________________________________ EXPORT<|

#* Activate Aliases *#
alias pI="expac \
	--humansize=M \
	--timefmt='%Y-%m-%d %T' '%l\t%m\t%n' \
	| sort | grep "
#TODO: List explicitly installed packages

alias pId="expac \
--timefmt='%Y-%m-%d %T' '%n |> %o' \
| sort | grep "
#TODO: List installed packages and their dependencies

pIv() {
	for app in "$@"; do
		expac --timefmt='%Y-%m-%d %T' '%n (%v) |> %o' |
			grep --color=always "^$app "
		echo ""
	done
}
# awk -f your_script.awk -v first_col=2 -v second_col=4 file
