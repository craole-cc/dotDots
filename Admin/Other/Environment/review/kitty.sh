#! /bin/sh
kittyTUX="$XDG_CONFIG_HOME/kitty"
kittyWIN="$WIN_CONFIG_HOME/kitty"
kittyDOTS="${DOTS_APP:?}/kitty"
kittyDATA="$WIN_APPDATA/kitty"

kittyCFG="$kittyDOTS/kitty.yml"
kittyCFG_WIN="$kittyWIN/kitty.yml"

#> Install <#
weHave kitty || Pin kitty

#> Verify Instalation <#
weHave kitty || return
"$NeedForSpeed" || weHave --report version kitty >>"$DOTS_loaded_apps"

#> Establish Link in HOME
case $sys_TYPE in
Windows)
	if [ ! -L "$kittyWIN" ]; then
		rm --recursive --force "$kittyWIN"
		ln --symbolic --force "$kittyDOTS/win" "$kittyWIN"
	fi
	;;
Linux)
	if [ ! -L "$kittyTUX" ]; then
		rm --recursive --force "$kittyTUX"
		ln --symbolic --force "$kittyDOTS/tux" "$kittyTUX"
	fi
	;;

*) ;;
esac

# ________________________________________ EXPORT<|

#* Activate Aliases *#
kitty_fonts() {
	if weHave vmore; then
		pager='vmore'
	elif weHave most; then
		pager='most'
	elif weHave bat; then
		pager='bat'
	elif weHave less; then
		pager='less'
	fi

	if [ "$#" = 0 ]; then
		if [ $pager ]; then
			kitty + list-fonts --psnames | $pager
		else
			kitty + list-fonts --psnames
		fi
	elif weHave rg; then
		kitty + list-fonts --psnames |
			rg --smart-case "$@"
	elif weHave grep; then
		kitty + list-fonts --psnames |
			grep --ignore-case "$@"
	fi
}

alias KF='kitty_fonts'
alias TE='kitty'
# alias kitty='kitty --config /home/qc/Dotfiles/Config/apps/kitty/kitty.conf'
