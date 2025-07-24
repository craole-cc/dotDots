#!/bin/sh

command -v weHave >/dev/null 2>&1 ||
  weHave() {
    command -v "$1" >/dev/null 2>&1 || return
  }

execute() {
  weHave "$1" || return 1
  "$@"
}
# Extracts any archive(s) (if unp isn't installed)
extract() {
  for archive in "$@"; do
    if [ -f "$archive" ]; then
      case "$archive" in
      *.tar.bz2) tar xvjf "$archive" ;;
      *.tar.gz) tar xvzf "$archive" ;;
      *.bz2) bunzip2 "$archive" ;;
      *.rar) rar x "$archive" ;;
      *.gz) gunzip "$archive" ;;
      *.tar) tar xvf "$archive" ;;
      *.tbz2) tar xvjf "$archive" ;;
      *.tgz) tar xvzf "$archive" ;;
      *.zip) unzip "$archive" ;;
      *.Z) uncompress "$archive" ;;
      *.7z) 7z x "$archive" ;;
      *) printf "Unknown archive type for %s" "$archive" ;;
      esac
    else
      printf "Error: %s is not a valid file!\n" "$archive" >&2
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
  execute rg --hidden --ignore-case --color=always "$1" . ||
    greps -iIHrn --color=always "$1" .

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
  unset _dir
  _limit=$1
  for ((i = 1; i <= _limit; i++)); do
    dir=$dir/..
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
distro_base() {
  _distribution="Unknown" # Default to unknown

  if nixos-version >/dev/null 2>&1; then
    _distribution="nixos"
  elif [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release

    case $ID in
    fedora | rhel | centos)
      _distribution="redhat"
      ;;
    sles | opensuse*)
      _distribution="suse"
      ;;
    ubuntu | debian)
      _distribution="debian"
      ;;
    gentoo)
      _distribution="Gentoo"
      ;;
    arch | manjaro)
      _distribution="arch"
      ;;
    slackware)
      _distribution="slackware"
      ;;
    *)
      #{ Check ID_LIKE if the Distribution is still not determined
      if [ -n "$ID_LIKE" ]; then
        case $ID_LIKE in
        *fedora* | *rhel* | *centos*)
          _distribution="redhat"
          ;;
        *sles* | *opensuse*)
          _distribution="suse"
          ;;
        *ubuntu* | *debian*)
          _distribution="debian"
          ;;
        *gentoo*)
          _distribution="gentoo"
          ;;
        *arch*)
          _distribution="arch"
          ;;
        *slackware*)
          _distribution="slackware"
          ;;
        esac
      fi
      ;;
    esac
  fi

  printf "%s" "$_distribution"
  unset _distribution
}

# Show the current version of the operating system
ver() {
  distribution

  case "$distribution" in
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

  unset distro
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

trim() {
  _var=$*
  _var="${_var#"${_var%%[![:space:]]*}"}" # remove leading whitespace characters
  _var="${_var%"${_var##*[![:space:]]}"}" # remove trailing whitespace characters
  printf "%s" "$_var"
  unset _var
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
  if weHave feh; then
    feh "$file"
  elif weHave sxiv; then
    sxiv "$file"
  elif weHave imv; then
    imv "$file"
  elif weHave nomacs; then
    nomacs "$file"
  elif weHave eog; then
    eog "$file"
  else
    printf 'Error: No image viewer found!\n' >&2
    return 1
  fi
}

peruse() {
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

  #{ Get MIME type using 'file' (POSIX-compliant)
  mime_type=$(file -bi "$file" | cut -d';' -f1)

  case "$mime_type" in
  application/pdf | text/html)
    if weHave firefox; then
      firefox "$file"
    elif weHave xdg-open; then
      xdg-open "$file"
    else
      printf 'Error: No application available for %s\n' "$mime_type" >&2
      return 1
    fi
    ;;
  image/*)
    if weHave feh; then
      feh "$file"
    elif weHave sxiv; then
      sxiv "$file"
    elif weHave imv; then
      imv "$file"
    elif weHave nomacs; then
      nomacs "$file"
    elif weHave eog; then
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
    if weHave xdg-open; then
      xdg-open "$file"
    else
      printf 'Error: No application found for %s\n' "$mime_type" >&2
      return 1
    fi
    ;;
  esac
}

# shellcheck disable=SC3040
skipPOSIX() {
  set +o posix
  "$@"
  set -o posix
  # echo "📌 Bypassed POSIX 👟 $* 🏁"
}
