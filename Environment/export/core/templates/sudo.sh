#!/bin/sh

#==================================================
#
# ROOT PRIVALAGES
# CLI/bin/environment/admin/sudo.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

for x in \
    mount \
    umount \
    sv \
    pacman \
    updatedb \
    su \
    shutdown \
    halt \
    poweroff \
    reboot \
    fc-cache \
    df \
    du \
    rm \
    reflector \
    powerpill \
    chsh \
    chmod \
    featherpad \
    notepadqq; do
    #/// shellcheck disable=SC2139
    alias $x='sudo $x'
    # x="sudo $x"
done

alias update="pacman -Syu"

# sudo() { 
#     if alias "$1" > /dev/null 2>&1 ; then 
#         $(type "$1" | sed -E 's/^.*`(.*).$/\1/') "${@:2}"
#     else 
#         command sudo "$@"
#     fi 
# }

update

alias S="sudo " # Allow alaises to work in root
alias doas="doas --"

# set -- "mount" "umount" "pacman"
# 		# sv |\
# 		# pacman \
# 		# updatedb \
# 		# su \
# 		# shutdown \
# 		# halt \
# 		# poweroff \
# 		# reboot \
# 		# fc-cache \
# 		# df \
# 		# du \
# 		# rm \
# 		# reflector \
# 		# powerpill \
# 		# chsh \
# 		# chmod \
# 		# featherpad \
# 		# notepadqq"
# value=$1

# [ " ${array[@]} " =~ " ${value} " ] && echo "true" || echo "false"
