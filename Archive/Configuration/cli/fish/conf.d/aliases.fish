#===============================================================
#
# ALIASES
# ~/.config/fish/conf.d/alias.fish
#
#===============================================================

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'
# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'
alias open='xdg-open'
alias h='history'
alias j='jobs -l'
# alias r='rlogin'
alias which='type -all'
alias ..='cd ..'
alias print='/usr/bin/lp -o nobanner -d $LPDEST'   # Assumes LPDEST is defined
alias pjet='enscript -h -G -fCourier9 -d $LPDEST'  # Pretty-print using enscript
alias background='xv -root -quit -max -rmode 5'    # Put a picture in the background
alias du='du -kh'
alias df='df -kTh'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias vifm='./.config/vifm/scripts/vifmrun'
alias calc='qalculate-gtk' &
alias cls='clear'
alias fm='sudo pcmanfm'
alias f='pcmanfm' &

# root privileges
alias doas="doas --"

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias dl='cd ~/Downloads'
alias con='cd ~/.config'
alias pic='cd ~/Pictures'
alias wal='cd ~/Pictures/Wallpapers'
alias mus='cd ~/Music'
alias bsh='open ~/.bashrc'

# System Info
alias neo='neofetch'
alias sys='paleofetch'

# vim and emacs
alias vim="nvim"
alias em="/usr/bin/emacs -nw"
alias emacs="emacsclient -c -a 'emacs'"
alias doomsync="~/.emacs.d/bin/doom sync"
alias doomdoctor="~/.emacs.d/bin/doom doctor"
alias doomupgrade="~/.emacs.d/bin/doom upgrade"
alias doompurge="~/.emacs.d/bin/doom purge"

# bat
alias cat='bat'

# broot
alias br='broot -dhp'
alias bs='broot --sizes'

# The 'ls' family (this assumes you use the GNU ls)
# alias la='ls -Al'               # show hidden files
# alias ls='ls -hF --color'	# add colors for filetype recognition
alias lx='ls -lXB'              # sort by extension
alias lk='ls -lSr'              # sort by size
alias lc='ls -lcr'		          # sort by change time
alias lu='ls -lur'		          # sort by access time
alias lr='ls -lR'               # recursive ls
# alias lt='ls -ltr'              # sort by date
alias lm='ls -al |more'         # pipe through 'more'
alias tree='tree -Csu'		# nice alternative to 'ls'

# Changing "ls" to "exa"
alias ls='exa -al --color=always --group-directories-first' # my preferred listing
alias la='exa -a --color=always --group-directories-first'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | egrep "^\."'

# df
alias dfsd='df -h | grep /dev/sd'
alias dus='du -s -h'

# lsblk
alias lsblk-details='lsblk --output=NAME,FSTYPE,FSVER,LABEL,PARTLABEL,MOUNTPOINT,FSAVAIL,FSUSE%'

# Tar
alias tar-gz-extract='tar -xzvf'
alias tar-gz-create='tar -czvf'

# tailoring 'less'
alias more='less'
export PAGER=less
export LESSCHARSET='latin1'
export LESSOPEN='|/usr/bin/lesspipe.sh %s 2>&-' # Use this if lesspipe.sh exists
export LESS='-i -N -w  -z-4 -g -e -M -X -F -R -P%t?f%f \
:stdin .?pb%pb\%:?lbLine %lb:?bbByte %bb:-...'

# Package Management
alias pacs='pacman -Ss'
alias pacu='sudo pacman -Syyu'                # update only standard pkgs
alias yaysua='yay -Sua --noconfirm'             # update only AUR pkgs (yay)
alias yaysyu='yay -Syu --noconfirm'             # update standard pkgs and AUR pkgs (yay)
alias parsua='paru -Sua --noconfirm'            # update only AUR pkgs (paru)
alias u='paru'                                  # update standard pkgs and AUR pkgs (paru)
alias p='paru'                                  # update standard pkgs and AUR pkgs (paru)
alias paq='paru -Qua'                           # print available AUR updates
alias pin='paru -S'                             # install package (paru)
alias prm='paru -Rsu'                           # remove package (paru)
alias prx='paru -Rsc'                           # remove package and dependencies (paru)
alias pao='pacman -Qdt'                         # list orphaned packages
alias pad='pacman -Qsq'                         # list dependent packages
alias unlock='sudo rm /var/lib/pacman/db.lck'   # remove pacman lock
alias cleanup='sudo pacman -Rns (pacman -Qtdq)' # remove orphaned packages
# alias umountext="udiskie-umount --detach"
alias pall="expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort"
alias pa20="expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort | tail -n 25"
alias pa10="expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort | tail -n 10"
alias fin='omf install'
alias fu='omf update'
alias fl='omf list'
alias ft='omf theme'
alias frm='omf remove'
alias frl='omf reload'
alias f='omf search'
alias fdoc='omf doctor'
alias frcf='rm ~/.config/fish/functions/fish_prompt.fish'


# get fastest mirrors
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# adding flags
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias lynx='lynx -cfg=~/.lynx/lynx.cfg -lss=~/.lynx/lynx.lss -vikeys'
alias vifm='./.config/vifm/scripts/vifmrun'

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

# General ps
alias pse='ps -e'
alias psf='ps -f'
alias psef='ps -ef'

# Merge Xresources
alias merge='xrdb -merge ~/.Xresources'

# git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias stat='git status'  # 'status' is protected name so using 'stat' instead
alias tag='git tag'
alias newtag='git tag -a'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# gpg encryption
# verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"

# youtube-dl
alias yta-aac="youtube-dl --extract-audio --audio-format aac "
alias yta-best="youtube-dl --extract-audio --audio-format best "
alias yta-flac="youtube-dl --extract-audio --audio-format flac "
alias yta-m4a="youtube-dl --extract-audio --audio-format m4a "
alias yta-mp3="youtube-dl --extract-audio --audio-format mp3 "
alias yta-opus="youtube-dl --extract-audio --audio-format opus "
alias yta-vorbis="youtube-dl --extract-audio --audio-format vorbis "
alias yta-wav="youtube-dl --extract-audio --audio-format wav "
alias ytv-best="youtube-dl -f bestvideo+bestaudio "

# switch between shells
# I do not recommend switching default SHELL from bash.
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

# bare git repo alias for dotfiles
alias config="/usr/bin/git --git-dir=$HOME/dotfiles --work-tree=$HOME"

# termbin
alias tb="nc termbin.com 9999"

# the terminal rickroll
alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

# Unlock LBRY tips
alias tips='lbrynet txo spend --type=support --is_not_my_input --blocking'

# Thinkorswim
alias tos="/home/craole/thinkorswim/thinkorswim"

# force all kakoune windows into one session
alias kak="/usr/bin/kak -c mysession"
alias kaks="/usr/bin/kak -s mysession"
alias kakd="/usr/bin/kak -d -s mysession &"

# df
alias dfsd='df -h | grep /dev/sd'
alias dus='du -s -h'

# lsblk
alias lsblk-details='lsblk --output=NAME,FSTYPE,FSVER,LABEL,PARTLABEL,MOUNTPOINT,FSAVAIL,FSUSE%'

# free
alias free='free -h'

# Tar
alias tar-gz-extract='tar -xzvf'
alias tar-gz-create='tar -czvf'

# Credijusto VPN
alias vpn-credijusto-connect="sudo systemctl start openvpn-client@credijusto.service"
alias vpn-credijusto-disconnect="sudo systemctl stop openvpn-client@credijusto.service"
alias vpn-credijusto-status="sudo systemctl status openvpn-client@credijusto.service"


# spelling typos - highly personnal#-------------------
# Personnal Aliases
#------------------- :-)
alias xs='cd'
alias vf='cd'
alias moer='more'
alias moew='more'
alias kk='ll'
