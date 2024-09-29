#! /bin/sh
# shellcheck disable=SC2034

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/Morganamilo/paru

# _________________________________________ LOCAL<|

PARU_CONF="$DOTS/Config/tools/utilities/paru/paru.conf"
DOTS_loaded_apps="${DOTS_loaded_apps:-$DOTS/Log/loaded_apps}"

#* Install *#
if weHave pacman; then
	if ! weHave paru; then
		CargoInstall paru
		# __updateGitUtils__
		# sudo pacman -S --needed base-devel
		# cd "$DOTS_DOWN/paru-bin" || return 1
		# makepkg -si
		# cd "$OLDPWD" || return
	fi
fi

#> Verify Instalation <#
if weHave paru; then
	weHave --report version paru >>"$DOTS_loaded_apps"
else
	return
fi

# _______________________________________ EXPORT<|

paru_install() {
	paru "$@" \
		--sync \
		--sudoloop \
		--disable-download-timeout \
		--quiet
}

paru_remove() {
	paru "$@" \
		--remove \
		--nosave \
		--cascade \
		--recursive \
		--unneeded
}

paru_update() {
	#| Sys & AUR
	paru_install \
		--refresh \
		--sysupgrade \
		--needed
}

paru_update_unattended() {
	#| Sys & AUR
	paru_install \
		--refresh \
		--sysupgrade \
		--needed \
		--noconfirm
}

paru_remote_search() { #| Search remote repositories
	paru "$@" \
		--sync \
		--color always \
		--search |
		less
}

paru_local_search() { #| Search installed applications
	for app in "$@"; do
		printf "%s\n {|> $app <|}\n"
		paru "$app" \
			--query \
			--color always \
			--search
	done
}

paru_query_upgrades() {
	paru "$@" \
		--query \
		--upgrades
}

paru_info() {
	paru "$@" \
		--sync \
		--info
}

paru_info_extended() {
	paru "$@" \
		--sync \
		--info
}

alias pin="paru_install"
alias pun="paru_remove"
alias pup="paru_update"
alias pupy="paru_update_unattended"
alias prs="paru_remote_search"
alias pls="paru_local_search"
alias pinf="paru_info"
alias pINF="paru_info_extended"
alias pqu="paru_query_upgrades"
