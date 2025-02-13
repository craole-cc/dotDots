#!/bin/sh

# command -v weHave >/dev/null 2>&1 ||
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
  dtype="unknown" # Default to unknown

  # Use /etc/os-release for modern distro identification
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release

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

skipPOSIX() {
  set +o posix
  "$@"
  set -o posix
  # echo "📌 Bypassed POSIX 👟 $* 🏁"
}

init_PS1() {
  # git dirty functions for prompt
  parse_git_dirty() {
    git status --porcelain 2>/dev/null && echo "*"
  }

  # This function is called in your prompt to output your active git branch.
  parse_git_branch() {
    git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
  }

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "$TERM" in xterm-color | *-256color) color_prompt=yes ;; esac

  if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
  fi

  if [ "$color_prompt" = yes ]; then
    RED="\[\033[0;31m\]"       # This syntax is some weird bash color thing I never
    LIGHT_RED="\[\033[1;31m\]" # really understood
    BLUE="\[\033[0;34m\]"
    CHAR="✚"
    CHAR_COLOR="\\33"
    PS1="[\[\033[30;1m\]\t\[\033[0m\]]$RED$(parse_git_branch) \[\033[0;34m\]\W\[\033[0m\]\n\[\033[0;31m\]$CHAR \[\033[0m\]"
  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  fi
  unset color_prompt force_color_prompt
}

# init_direnv() {
#   weHave direnv || return
#   eval "$(direnv hook bash)"
# }
init_direnv() {
  command -v direnv >/dev/null 2>&1 || return
  eval "$(direnv hook bash)" || true
}

init_fasfetch() {
  command -v fastfetch >/dev/null 2>&1 || return
  : "${FASTFETCH_CONFIG:=${DOTS_CFG}/fastfetch/config.jsonc}"
  export FASTFETCH_CONFIG
  fastfetch --config "$FASTFETCH_CONFIG"
}

init_starship() {
  #@ Check if starship exists, return if not
  command -v starship >/dev/null 2>&1 || return

  #@ Set config path with POSIX-compliant parameter expansion
  : "${STARSHIP_CONFIG:=${DOTS_CFG}/starship/starship.toml}"
  export STARSHIP_CONFIG

  #@ Initialize starship (no POSIX mode toggling)
  eval "$(starship init bash)" || true
}

init_zoxide() {
  command -v zoxide >/dev/null 2>&1 || return
  eval "$(zoxide init bash)" || true
  # eval "$(zoxide init posix --hook prompt)" || true
}

init_prompt() {
  #| Tools
  init_direnv
  init_zoxide

  #| System Information
  # init_fasfetch

  #| Prompt
  init_starship
  status=$?
  if [ "$status" -ne 0 ]; then
    init_PS1
  fi
}

update_dots_path() {
  #@ Get the base directory
  BASE_DIR="$1"

  #@ Define exclusion patterns at the top level for reusability
  EXCLUDE_PATTERNS="review temp tmp archive backup"
  unset exclude_args pattern

  #@ Create temporary file securely
  TMP_FILE=$(mktemp)
  trap 'rm -f "$TMP_FILE"' EXIT

  if command -v fd >/dev/null 2>&1; then
    #@ Convert patterns to fd --exclude args
    for pattern in $EXCLUDE_PATTERNS; do
      exclude_args="$exclude_args --exclude '$pattern'"
    done

    #@ Store fd command and options
    find_cmd="fd ."
    find_opt="--type d $exclude_args"
  else
    #@ Convert patterns to find -iname args
    for pattern in $EXCLUDE_PATTERNS; do
      [ -n "$find_pattern" ] && find_pattern="$find_pattern -o"
      find_pattern="$find_pattern -iname '$pattern'"
    done

    #@ Store fd command and options
    find_cmd="find"
    find_opt="-type d \( $find_pattern \) -prune -o -type d -print"
  fi

  #@ Build find/fd command with dynamic exclusion patterns
  #@ eval is necessary here for POSIX compliance since arrays aren't available
  #@ and we need to construct a complex command with multiple patterns.
  #@ This is safe since EXCLUDE_PATTERNS is defined within the script.
  eval "$find_cmd" "$BASE_DIR" "$find_opt" >"$TMP_FILE"

  # @Include base dir first if it exists and isn't excluded
  case ":$PATH:" in
  ":$BASE_DIR:") ;;
  *) temp_path="${PATH}:${BASE_DIR}" ;;
  esac

  #@ Build updated path
  while IFS= read -r dir; do
    case ":$temp_path:" in
    ":$dir:") ;;
    *) temp_path="${temp_path}:${dir}" ;;
    esac
  done <"$TMP_FILE"

  #@ Update the PATH variable
  PATH="$temp_path"
  export PATH
}
