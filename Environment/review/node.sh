#! /bin/sh

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/Morganamilo/paru

# _________________________________________ LOCAL<|

#* Install *#
if weHave pacman; then
	if ! weHave paru; then
		__updateGitUtils__
		sudo pacman -S --needed base-devel
		cd "$DOTS_DOWN/paru-bin" || return 1
		makepkg -si
		cd "$OLDPWD" || return
	fi
fi

#> Verify Instalation <#
if weHave paru; then
	weHave --report version paru >>"$DOTS_loaded_apps"
else
	return
fi

# _______________________________________ EXPORT<|

#* Activate Aliases *#
alias P="paru" p="paru"

#
#>>= Query =<<#
Ps() {
	paru "$@" \
		--sync \
		--color always \
		--search |
		less
} #TODO: Search remote repositories for matching strings

Psl() {
	for app in "$@"; do
		printf "%s\n {|> $app <|}\n"
		paru "$app" \
			--query \
			--color always \
			--search
	done
} #TODO: Search installed applications for matching strings

alias Pi="paru -Si"   #TODO: Info
alias Pid="paru -Sii" #TODO: Include more info

#>>= Install =<<#

Pin() {
	paru "$@" \
		--sync \
		--sudoloop \
		--disable-download-timeout \
		--quiet
} # TODO: Reduce timeout risk during installation

#>>= Uninstall =<<#
Prm() {
	paru "$@" \
		--remove \
		--recursive \
		--unneeded
}

alias Prm="paru -Rsu" #TODO: Remove
alias Prd="paru -Rsc" #TODO: Include Dependencies

#>>= Update =<<#
Pup() {
	Pin \
		--refresh \
		--sysupgrade \
		--needed \
		--noconfirm
}

alias Pul="paru -Qu"              #TODO: List Updates
alias Pu="paru -Syu --noconfirm"  #TODO: Sys & AUR
alias Pua="paru -Sua --noconfirm" #TODO: AUR
