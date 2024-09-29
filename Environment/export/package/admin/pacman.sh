#! /bin/sh

#==================================================
#
# Paru
#
#==================================================

# _________________________________ DOCUMENTATION<|

#TODO: https://github.com/Morganamilo/paru

# _________________________________________ LOCAL<|

#* Verify Instalation *#
if ! type pacman >/dev/null 2>&1; then
  return
fi

# _______________________________________ EXPORT<|

#* Activate Aliases *#
# >>= Search =<< #

# >>= Update =<< #
alias pup="sudo pacman -Syyu --needed"              #| Update/Upgrade
alias pupy="sudo pacman -Syyu --noconfirm --needed" #| Update/Upgrade

# >>= List =<< #
alias pO="pacman -Qdt" # Orphaned
alias pD="pacman -Qsq" # Dependencies
alias pIe="comm -23 <(pacman -Qqett | sort) <(pacman -Qqg base-devel | sort | uniq)
"
alias pl="pacman -Qlk" # All locations

alias pcl='pacman -Rns $(pacman -Qtdq); paccache -ruk0' # Remove Orphans
alias prl="sudo rm /var/lib/pacman/db.lck"              # Remove Pacman Lock
alias Pin='sudo pacman -Syu'
