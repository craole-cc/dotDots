#!/usr/bin/env bash
scr_path="$(realpath "${BASH_SOURCE[0]}")"
scr_dir="$(dirname "$scr_path")"

source_configs() {
  [ -f /etc/bashrc ] && . /etc/bashrc
  [ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"
  [ -f "$HOME/.bash_functions" ] && . "$HOME/.bash_functions"
  [ -f "$HOME/.profile" ] && . "$HOME/.profile"
}

init_utilities() {
  wehave() {
    command -v "$1" >/dev/null 2>&1
  }

  execute() {
    wehave "$1" || return 1
    "$@"
  }
  # Extracts any archive(s) (if unp isn't installed)
  extract() {
    for archive in "$@"; do
      if [ -f "$archive" ]; then
        case $archive in
        *.tar.bz2) tar xvjf $archive ;;
        *.tar.gz) tar xvzf $archive ;;
        *.bz2) bunzip2 $archive ;;
        *.rar) rar x $archive ;;
        *.gz) gunzip $archive ;;
        *.tar) tar xvf $archive ;;
        *.tbz2) tar xvjf $archive ;;
        *.tgz) tar xvzf $archive ;;
        *.zip) unzip $archive ;;
        *.Z) uncompress $archive ;;
        *.7z) 7z x $archive ;;
        *) echo "don't know how to extract '$archive'..." ;;
        esac
      else
        echo "'$archive' is not a valid file!"
      fi
    done
  }

  # Searches for text in all files in the current folder
  ftext() {
    # -i case-insensitive
    # -I ignore binary files
    # -H causes filename to be printed
    # -r recursive search
    # -n causes line number to be printed
    # optional: -F treat search term as a literal, not a regular expression
    # optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
    {
      execute rg --hidden --ignore-case --color=always "$1" . ||
        greps -iIHrn --color=always "$1" .
    } | bat
  }

  # Copy file with a progress bar
  cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
      awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
  }

  # Copy and go to the directory
  cpg() {
    if [ -d "$2" ]; then
      cp "$1" "$2" && cd "$2"
    else
      cp "$1" "$2"
    fi
  }

  # Move and go to the directory
  mvg() {
    if [ -d "$2" ]; then
      mv "$1" "$2" && cd "$2"
    else
      mv "$1" "$2"
    fi
  }

  # Create and go to the directory
  mkdirg() {
    mkdir -p "$1"
    cd "$1"
  }

  # Goes up a specified number of directories  (i.e. up 4)
  up() {
    local d=""
    limit=$1
    for ((i = 1; i <= limit; i++)); do
      d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
      d=..
    fi
    cd $d
  }

  # Automatically do an ls after each cd, z, or zoxide
  cd() {
    if [ -n "$1" ]; then
      builtin cd "$@" && ls
    else
      builtin cd ~ && ls
    fi
  }

  # Show the current distribution
  distribution() {
    local dtype="unknown" # Default to unknown

    # Use /etc/os-release for modern distro identification
    if [ -r /etc/os-release ]; then
      source /etc/os-release
      case $ID in
      fedora | rhel | centos)
        dtype="redhat"
        ;;
      sles | opensuse*)
        dtype="suse"
        ;;
      ubuntu | debian)
        dtype="debian"
        ;;
      gentoo)
        dtype="gentoo"
        ;;
      arch | manjaro)
        dtype="arch"
        ;;
      slackware)
        dtype="slackware"
        ;;
      *)
        # Check ID_LIKE only if dtype is still unknown
        if [ -n "$ID_LIKE" ]; then
          case $ID_LIKE in
          *fedora* | *rhel* | *centos*)
            dtype="redhat"
            ;;
          *sles* | *opensuse*)
            dtype="suse"
            ;;
          *ubuntu* | *debian*)
            dtype="debian"
            ;;
          *gentoo*)
            dtype="gentoo"
            ;;
          *arch*)
            dtype="arch"
            ;;
          *slackware*)
            dtype="slackware"
            ;;
          esac
        fi

        # If ID or ID_LIKE is not recognized, keep dtype as unknown
        ;;
      esac
    fi

    printf "%s" "$dtype"
  }

  # Show the current version of the operating system
  ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
    "redhat")
      if [ -s /etc/redhat-release ]; then
        cat /etc/redhat-release
      else
        cat /etc/issue
      fi
      uname -a
      ;;
    "suse")
      cat /etc/SuSE-release
      ;;
    "debian")
      lsb_release -a
      ;;
    "gentoo")
      cat /etc/gentoo-release
      ;;
    "arch")
      cat /etc/os-release
      ;;
    "slackware")
      cat /etc/slackware-version
      ;;
    *)
      if [ -s /etc/issue ]; then
        cat /etc/issue
      else
        echo "Error: Unknown distribution"
        exit 1
      fi
      ;;
    esac
  }

  # IP address lookup
  whatsmyip() {
    #| Internal IP Lookup.
    printf "Internal IP: %s\n" "$(
      execute ip addr show enp9s0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 ||
        execute ifconfig enp9s0 | grep "inet " | awk '{print $2}'
    )"

    #| External IP Lookup
    printf "External IP: %s\n" "$(
      execute hostname -i | cut -d' ' -f1 ||
        execute curl -s ifconfig.me
    )"
  }

  # View Apache logs
  apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
      cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
      cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    fi
  }

  # Edit the Apache configuration
  apacheconfig() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
      sedit /etc/httpd/conf/httpd.conf
    elif [ -f /etc/apache2/apache2.conf ]; then
      sedit /etc/apache2/apache2.conf
    else
      echo "Error: Apache config file could not be found."
      echo "Searching for possible locations:"
      sudo updatedb && locate httpd.conf && locate apache2.conf
    fi
  }

  # Edit the PHP configuration file
  phpconfig() {
    if [ -f /etc/php.ini ]; then
      sedit /etc/php.ini
    elif [ -f /etc/php/php.ini ]; then
      sedit /etc/php/php.ini
    elif [ -f /etc/php5/php.ini ]; then
      sedit /etc/php5/php.ini
    elif [ -f /usr/bin/php5/bin/php.ini ]; then
      sedit /usr/bin/php5/bin/php.ini
    elif [ -f /etc/php5/apache2/php.ini ]; then
      sedit /etc/php5/apache2/php.ini
    else
      echo "Error: php.ini file could not be found."
      echo "Searching for possible locations:"
      sudo updatedb && locate php.ini
    fi
  }

  # Edit the MySQL configuration file
  mysqlconfig() {
    if [ -f /etc/my.cnf ]; then
      sedit /etc/my.cnf
    elif [ -f /etc/mysql/my.cnf ]; then
      sedit /etc/mysql/my.cnf
    elif [ -f /usr/local/etc/my.cnf ]; then
      sedit /usr/local/etc/my.cnf
    elif [ -f /usr/bin/mysql/my.cnf ]; then
      sedit /usr/bin/mysql/my.cnf
    elif [ -f ~/my.cnf ]; then
      sedit ~/my.cnf
    elif [ -f ~/.my.cnf ]; then
      sedit ~/.my.cnf
    else
      echo "Error: my.cnf file could not be found."
      echo "Searching for possible locations:"
      sudo updatedb && locate my.cnf
    fi
  }

  # Trim leading and trailing spaces (for scripts)
  trim() {
    local var=$*
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
    printf '%s' "$var"
  }

  gcom() {
    git add --all
    git commit --message "$1"
  }

  lazyg() {
    git add --all
    git commit --message "$1"
    git push
  }

  toolty() {
    execute nix-shell -p \
      fzf \
      eza \
      lsd \
      delta \
      bat \
      yazi \
      tlrc \
      tokei \
      thefuck \
      zoxide \
      tldr \
      neovim \
      ripgrep \
      helix
  }

  edit() {
    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
      "${VISUAL:-${EDITOR:-vi}}" "$@" &
    else
      "${EDITOR:-vi}" "$@" &
    fi
  }

  view() {
    if wehave feh; then
      feh "$file"
    elif wehave sxiv; then
      sxiv "$file"
    elif wehave imv; then
      imv "$file"
    elif wehave nomacs; then
      nomacs "$file"
    elif wehave eog; then
      eog "$file"
    else
      printf 'Error: No image viewer found!\n' >&2
      return 1
    fi
  }

  scan() {
    "${READER:-less}" "$@"
  }

  open() {
    [ $# -eq 0 ] && {
      printf 'Usage: open <file>\n' >&2
      return 1
    }

    file="$1"
    [ -f "$file" ] || {
      printf 'Error: File not found: %s\n' "$file" >&2
      return 1
    }

    #@ Get MIME type using 'file' (POSIX-compliant)
    mime_type=$(file -bi "$file" | cut -d';' -f1)

    case "$mime_type" in
    application/pdf | text/html)
      if wehave firefox; then
        firefox "$file"
      elif wehave xdg-open; then
        xdg-open "$file"
      else
        printf 'Error: No application available for %s\n' "$mime_type" >&2
        return 1
      fi
      ;;
    image/*)
      if wehave feh; then
        feh "$file"
      elif wehave sxiv; then
        sxiv "$file"
      elif wehave imv; then
        imv "$file"
      elif wehave nomacs; then
        nomacs "$file"
      elif wehave eog; then
        eog "$file"
      else
        printf 'Error: No image viewer found!\n' >&2
        return 1
      fi
      ;;
    text/*)
      edit "$file"
      ;;
    *)
      if wehave xdg-open; then
        xdg-open "$file"
      else
        printf 'Error: No application found for %s\n' "$mime_type" >&2
        return 1
      fi
      ;;
    esac
  }

}

define_exports() {
  #| Paths [Configuration]
  BASHRC="$scr_path"
  BDOTDIR="$scr_dir"
  DOTS_CFG="$(dirname "$scr_dir")"
  export BASHRC BDOTDIR DOTS_CFG

  #| Paths [Data]
  XDG_DATA_HOME="$HOME/.local/share"
  XDG_CONFIG_HOME="$HOME/.config"
  XDG_STATE_HOME="$HOME/.local/state"
  XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME

  #| History
  shopt -s histappend
  HISTFILESIZE=10000
  HISTSIZE=500
  HISTTIMEFORMAT="%F %T" # add timestamp to history
  HISTCONTROL=erasedups:ignoredups:ignorespace
  export HISTFILESIZE HISTSIZE HISTTIMEFORMAT HISTCONTROL

  PROMPT_COMMAND='history -a'
  # export PROMPT_COMMAND

  #| Default TTY Editor
  if wehave hx; then
    EDITOR="hx"
  elif wehave nvim; then
    EDITOR="nvim"
  elif wehave nano; then
    EDITOR="nano"
  else
    EDITOR="vi"
  fi
  export EDITOR

  #| Default GUI Editor
  if wehave code; then
    VISUAL="code"
  elif wehave code-insiders; then
    VISUAL="code-insiders"
  elif wehave codium; then
    VISUAL="codium"
  elif wehave zeditor; then
    VISUAL="zeditor"
  else
    VISUAL="$EDITOR"
  fi
  export VISUAL

  #| Default TTY Reader/Pager
  if wehave bat; then
    READER="bat"
  elif wehave most; then
    READER="most"
  elif wehave less; then
    READER="less"
  elif wehave more; then
    READER="more"
  else
    READER="cat"
  fi
  export READER

  #| Default TTY Photo Viewer

  #| Colors
  #@ for ls and all grep commands such as grep, egrep and zgrep
  CLICOLOR=1
  LS_COLORS="no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:"
  export CLICOLOR LS_COLORS

  #@ for manpages in less makes manpages a little easier to read
  LESS_TERMCAP_mb=$'\E[01;31m'
  LESS_TERMCAP_md=$'\E[01;31m'
  LESS_TERMCAP_me=$'\E[0m'
  LESS_TERMCAP_se=$'\E[0m'
  LESS_TERMCAP_so=$'\E[01;44;33m'
  LESS_TERMCAP_ue=$'\E[0m'
  LESS_TERMCAP_us=$'\E[01;32m'
  export LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me LESS_TERMCAP_se LESS_TERMCAP_so LESS_TERMCAP_ue LESS_TERMCAP_us
}

define_aliases() {
  # Check the window size after each command and, if necessary, update the values of LINES and COLUMNS
  shopt -s checkwinsize

  # Allow ctrl-S for history navigation (with ctrl-R)
  [[ $- == *i* ]] && stty -ixon

  # Alias's to change the directory
  alias web='cd /var/www/html'

  # Alias's to mount ISO files
  # mount -o loop /home/NAMEOFISO.iso /home/ISOMOUNTDIR/
  # umount /home/NAMEOFISO.iso
  # (Both commands done as root only.)

  #######################################################
  # GENERAL ALIAS'S
  #######################################################
  alias b='init_prompt'
  alias B='init_prompt_blank; clear'
  alias bx='bash --noprofile --norc'
  alias Bx='bx; clear'

  # To temporarily bypass an alias, we precede the command with a \
  # EG: the ls command is aliased, but to use the normal ls command you would type \ls

  # Add an "alert" alias for long running commands.  Use like so:
  #   sleep 10; alert
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

  # Edit this .bashrc file
  alias ebrc='edit ~/.bashrc'

  # Show help for this .bashrc file
  alias hlp='less ~/.bashrc_help'

  # alias to show the date
  alias da='date "+%Y-%m-%d %A %T %Z"'

  # Alias's to modified commands
  alias cp='cp -i'
  alias mv='mv -i'
  alias rm='trash -v'
  alias mkdir='mkdir -p'
  alias ps='ps auxf'
  alias ping='ping -c 10'
  alias less='less -R'
  alias cls='clear'
  alias apt-get='sudo apt-get'
  alias multitail='multitail --no-repeat -c'
  alias freshclam='sudo freshclam'
  alias vi='nvim'
  alias svi='sudo vi'
  alias vis='nvim "+set si"'

  # Change directory aliases
  alias home='cd ~'
  alias cd..='cd ..'
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
  alias .....='cd ../../../..'

  # cd into the old directory
  alias bd='cd "$OLDPWD"'

  # Remove a directory and all files
  alias rmd='/bin/rm  --recursive --force --verbose '

  # Alias's for multiple directory listing commands
  alias la='ls -Alh'                # show hidden files
  alias ls='ls -aFh --color=always' # add colors and file type extensions
  alias lx='ls -lXBh'               # sort by extension
  alias lk='ls -lSrh'               # sort by size
  alias lc='ls -ltcrh'              # sort by change time
  alias lu='ls -lturh'              # sort by access time
  alias lr='ls -lRh'                # recursive ls
  alias lt='ls -ltrh'               # sort by date
  alias lm='ls -alh |more'          # pipe through 'more'
  alias lw='ls -xAh'                # wide listing format
  alias ll='ls -Fls'                # long listing format
  alias labc='ls -lap'              # alphabetical sort
  alias lf="ls -l | egrep -v '^d'"  # files only
  alias ldir="ls -l | egrep '^d'"   # directories only
  alias lla='ls -Al'                # List and Hidden Files
  alias las='ls -A'                 # Hidden Files
  alias lls='ls -l'                 # List

  # alias chmod commands
  alias mx='chmod a+x'
  alias 000='chmod -R 000'
  alias 644='chmod -R 644'
  alias 666='chmod -R 666'
  alias 755='chmod -R 755'
  alias 777='chmod -R 777'

  # Search command line history
  alias h="history | grep "

  # Search running processes
  alias p="ps aux | grep "
  alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

  # Search files in the current folder
  alias f="find . | grep "

  # Count all files (recursively) in the current folder
  alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

  # To see if a command is aliased, a file, or a built-in command
  alias checkcommand="type -t"

  # Show open ports
  alias openports='netstat -nape --inet'

  # Alias's for safe and forced reboots
  alias rebootsafe='sudo shutdown -r now'
  alias rebootforce='sudo shutdown -r -n now'

  # Alias's to show disk space and space used in a folder
  alias diskspace="du -S | sort -n -r |more"
  alias folders='du -h --max-depth=1'
  alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
  alias tree='tree -CAhF --dirsfirst'
  alias treed='tree -CAFd'
  alias mountedinfo='df -hT'

  # Alias's for archives
  alias mktar='tar -cvf'
  alias mkbz2='tar -cvjf'
  alias mkgz='tar -cvzf'
  alias untar='tar -xvf'
  alias unbz2='tar -xvjf'
  alias ungz='tar -xvzf'

  # Show all logs in /var/log
  alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"

  # SHA1
  alias sha1='openssl sha1'

  alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'

  # KITTY - alias to be able to use kitty features when connecting to remote servers(e.g use tmux on remote server)
  alias kssh="kitty +kitten ssh"

  # alias to cleanup unused docker containers, images, networks, and volumes
  alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '

  alias ff='fastfetch --config "$FASTFETCH_CONFIG"'
}

init_starship() {
  wehave starship || return

  STARSHIP_CONFIG="${DOTS_CFG}/starship/starship.toml"
  # PROMPT_COMMAND=(history -a 'starship_precmd')
  export STARSHIP_CONFIG PROMPT_COMMAND
  eval "$(starship init bash)"

}
init_zoxide() {
  wehave zoxide || return
  eval "$(zoxide init bash)"
}
init_fasfetch() {
  wehave fastfetch || return
  FASTFETCH_CONFIG="${DOTS_CFG}/fastfetch/config.jsonc"
  export FASTFETCH_CONFIG
  fastfetch --config "$FASTFETCH_CONFIG"
}

init_prompt() {
  init_fasfetch
  init_starship
  init_zoxide

}

init_utilities
source_configs
define_exports
define_aliases
init_prompt
