#! /bin/sh

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/Morganamilo/paru

# _________________________________________ LOCAL<|

#> Verify Instalation <#
weHave reflector || return
"$NeedForSpeed" || weHave --report version reflector >>"$DOTS_loaded_apps"
# _______________________________________ EXPORT<|

#* Activate Aliases *#

alias mr="reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mrd="reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mrs="reflector --latest 50 --number 20 --verbose --sort score --save /etc/pacman.d/mirrorlist"
alias mra="reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
