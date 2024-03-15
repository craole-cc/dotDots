#!/bin/sh
# shellcheck disable=SC2154
#==================================================
#
# COMMON ALIASES
# $shENV/admin/linux_defaults.sh
#

#@ _________________________________________ DOCUMENTATION<|

# _______________________________________ TWEAKS<|

# >>= Config =<< #
# Usage: function <command> => cfB vim
cfBASH() { $1 "$RC_bash"; }
cfDASH() { $1 "$RC_dash"; }
cfZSH() { $1 "$RC_zsh"; }
cfPWSH() { $1 "$RC_pwsh"; }
cfX11() { $1 "$RC_xinit"; }
cfGIT() { $1 "$GIT_CONFIG"; }
cfSSH() { $1 "$RC_ssh"; }
cfFSH() { $1 "$RC_fish"; }
cfINI() { $1 "$RC_init"; }
cfDOT() { ede "$codeDOTS"; }

# --> Change Shell Permanently
csB() { chsh "$USER" -s /bin/bash; }
csD() { chsh "$USER" -s /bin/dash; }
csZ() { chsh "$USER" -s /bin/zsh; }

# >>= Shell =<< #
alias B='clear; bash' b='bash' \
  D='clear; dash' d='dash' \
  Z='clear; zsh' z='zsh'
alias envSH='env | less'

# >>= System Info =<< #
alias du="du -kh"
alias df="df -kTh" # human-readable sizes
alias dfsd="df -h | grep /dev/sd"
alias dus="du -s -h"
alias dust="dust --reverse"
alias free="free -m" # show sizes in MB
alias pth="path"
alias lsb="lsblk --output=NAME,FSTYPE,FSVER,LABEL,PARTLABEL,MOUNTPOINT,FSAVAIL,FSUSE%"
alias jctl="journalctl -p 3 -xb"

# >>= Common =<< #e
alias k="killall"
alias X='exit'
alias sdn="shutdown -h now"
alias h="showhist"
alias j="jobs -l"
alias which="command -v"
alias ..="cd .."
alias cls="clear" c="clear"
alias xk="xev -event keyboard" # keyboard mapping
alias xp="xprop"
alias font="fc-cache -f -v"
alias sc="clear; shellcheck"
alias eq='calk' cq='calk' calc='calk'

# >>= Process Management =<< #

alias mem="ps auxf | sort -nr -k 4 | head -5"
alias mem10="ps auxf | sort -nr -k 4 | head -10"
alias mema="ps auxf | sort -nr -k 4"
alias cpu="ps auxf | sort -nr -k 3 | head -5"
alias cpu10="ps auxf | sort -nr -k 3 | head -10"
alias cpua="ps auxf | sort -nr -k 3"

eo() {
  # if weHave emojify; then
  if emojify --version type >/dev/null 2>&1; then
    emojify "$*"
  else
    printf "%s$*"
  fi
}

# ----------------------------
# ------ File Management -----
# ----------------------------

# >>= File Operation Confirmation =<< #
alias cp="cp -i"                 # "cp -iv"
alias mv="mv -i"                 # "mv -iv"
alias rm='rm -I --preserve-root' #"rm -vI"
alias bc="bc -ql"
alias md="mkdir --parents --verbose"
alias ln='ln -i'
mcd() {
  newdir="$*"
  mkdir --parents "$newdir"
  cd "$newdir" || return
}
alias mkcd='mcd'

# >>= List =<< #
alias ls='ls --color=always --classify'
alias la='ls --almost-all --group-directories-first'
alias ll='la -l --human-readable'
alias lr='ls --recursive | less'
alias lR='ll --recursive | less'
alias lsD='ll --sort=time'
alias lsS='ll --sort=size'
alias lsH='ls --help'
alias lsc='readlink -f "$(ls -d)"'

alias diff="diff --color=auto"
alias ccat="highlight --out-format=ansi"
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ----------------------------
# ---- Window Management ----
# ----------------------------

# >>= XMonad =<< #
alias XMr="xmonad --recompile"

# >>= Archives =<< #
alias tarc="tar -czvf" # Create
alias tarx="tar -xzvf" # Extract

# >>= Wallpapers =<< #
alias wal='sxiv -tfqrn 200 "$WALLPAPERS" &'
alias walFr='feh --recursive --randomize --bg-fill "$WALLPAPERS" &'
alias walF="~/.fehbg &"
alias walN="nitrogen --restore &"
alias walV="variety &"

# >>= Music =<< #
alias mus="musikcube"
alias cm="cmus"
alias cr="curseradio"
alias music='"mpv --shuffle "$(find "$MUSIC")"'

# >>= YouTube =<< #
alias yt="pipe-viewer"
alias ytd="youtube-dl --add-metadata -i"
alias ytda="yt -x -f bestaudio/best"
alias ytdv="youtube-dl -f bestvideo+bestaudio "
alias ffmpeg="ffmpeg -hide_banner"
alias ytda-aac="youtube-dl --extract-audio --audio-format aac "
alias ytda-best="youtube-dl --extract-audio --audio-format best "
alias ytda-flac="youtube-dl --extract-audio --audio-format flac "
alias ytda-m4a="youtube-dl --extract-audio --audio-format m4a "
alias ytda-mp3="youtube-dl --extract-audio --audio-format mp3 "
alias ytda-opus="youtube-dl --extract-audio --audio-format opus "
alias ytda-vorbis="youtube-dl --extract-audio --audio-format vorbis "
alias ytda-wav="youtube-dl --extract-audio --audio-format wav "
alias yt_mp3="yt-dlp --extract-audio --audio-format mp3 --audio-quality 0"

# ----------------------------
# --- Clipboard Management ---
# ----------------------------

case $sys_INFO in
*Windows*)
  alias copy="clip.exe"
  alias paste="powershell.exe Get-Clipboard"
  ;;
*Mac*)
  alias copy="pbcopy"
  alias paste="pbpaste"
  ;;
*Linux*)
  alias copy="xclip -sel clip"
  alias paste="xclip -sel clip -o"
  ;;
*)
  alias copy="/dev/clipboard"
  alias paste="cat /dev/clipboard"
  ;;
esac

alias ko='eko -n'
alias ver3n='weHave --report version'
alias ffx='firefox --private-window &'
alias code='VScode'
