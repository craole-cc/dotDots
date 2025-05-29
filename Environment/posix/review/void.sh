#!/bin/sh

EDITOR='nvim'
READER='bat'

#| Elevated Privileges
[ "${EUID:-$(id -u)}" -eq 0 ] && isROOT=true

#> Commands
if [ "$isROOT" ]; then
  _sv_() { sv "$@"; }
  _rm_() { rm "$@"; }
  _ln_() { ln "$@"; }
  _chown_() { chown "$@"; }
  _chmod_() { chmod "$@"; }
  _mkdir_() { sudo mkdir "$@"; }
else
  _sv_() { sudo sv "$@"; }
  _rm_() { sudo rm "$@"; }
  _ln_() { sudo ln "$@"; }
  _chown_() { sudo cho "$@"; }
  _chmod_() { sudo chmod "$@"; }
  _mkdir_() { sudo mkdir "$@"; }
fi

#| XDG
# XDG_RUNTIME_DIR=/run/user/$(id -u)
#if [ ! "$Root" ] ;then
#	[ -d "$XDG_RUNTIME_DIR" ] ||
# 		_mkdir_ --parents "$XDG_RUNTIME_DIR"
# 	_chown_ ${USER}:${USER} "$XDG_RUNTIME_DIR"
# 	_chmod_ 700 "$XDG_RUNTIME_DIR"
#fi

#| BIN to PATH

# save_array() {
# 	for i do
# 		printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/"
# 	done
# 	echo " "
# }

# find_array() {
# 	find "$@" -exec sh -c "for i do printf %s\\\\n \"\$i\" \\
# 	| sed \"s/'/'\\\\\\\\''/g;1s/^/'/;\\\$s/\\\$/' \\\\\\\\/\"
# done" dummy '{}' +
# }

# BINS=$(save_array "$@")
# set -- \
# 	"$HOME/.local/bin" \
# 	"$HOME/Test/bin"

# for BIN in $( find "$@" ) ;do
# 	if [ -d "$BIN" ] ;then

# 		case ":$PATH:" in
# 			*:"$BIN":*) ;;
# 			*) PATH="$PATH:$BIN"
# 		esac

# 	elif [ -f "$BIN" ] && [ -O "$BIN" ] ;then
# 		chmod +x "$BIN"
# 	fi
# done

# eval "set -- $BINS"

#> Run Commands Files
rcEdit() {
  #| Help
  __help__() {
    _USAGE="::USAGE:: rcEdit [RC] <EDITOR>"
    printf "%s\n" "$_USAGE"
    return 1
  }

  __opts__() {
    case "$1" in
    '-h' | '--help') __help__ ;;
    *)
      if [ "$#" -eq 0 ]; then
        __help__
      else
        __process__ "$@"
      fi
      ;;
    esac
  }

  __process__() {
    #| Validate RC File
    if [ -f "$1" ]; then
      _RC="$1"
    else
      printf "%s is not a valid config file\n" "$_RC"
    fi

    #| Set Editor
    if
      command -v "$2" &
      >/dev/null
    then
      _EDITOR="$2"
    else
      _EDITOR="$EDITOR"
    fi

    #| Process
    if
      #| Root or Owner
      [ "$isROOT" ] || [ -O "$_RC" ]
    then
      "$_EDITOR" "$_RC"
    else
      sudo "$_EDITOR" "$_RC"
    fi
  }

  #| Cleanup
  __cleanup__() { unset _RC _EDITOR _USAGE; }

  #| Main
  __opts__ "$@"
  __cleanup__
}

RC_ALIAS_VOID="/etc/bash/bashrc.d/alias-void.sh" &&
  alias rcAliasVoid='rcEdit "$RC_ALIAS_VOID"'

RC_LOCAL="/etc/rc.local" &&
  alias rcLocal='rcEdit "$RC_LOCAL"'

RC_BASH_USER="/home/craole/.bashrc" &&
  alias rcBashUser='rcEdit "$RC_BASH_USER"'

RC_PROFILE="/home/craole/.profile" &&
  alias rcProfile='rcEdit "$RC_PROFILE"'

#> Package Manager
if [ ! "$isROOT" ]; then
  alias xbps-install='sudo xbps-install'
  alias xbps-remove='sudo xbps-remove'
  alias xbps-query='sudo xbps-query'
  alias xbps-reconfigure='sudo xbps-reconfigure'
  alias xcheckrestart='sudo xcheckrestart'
fi
alias pacInstall='xbps-install --sync --update --verbose'
alias pacUninstall='xbps-remove --recursive --remove-orphans --clean-cache --verbose'
alias pacQuery='xbps-query -Rs'
alias pacCheckR='xcheckrestart'
alias pacRconf='xbps-reconfigure'

#> Services
alias svUp='sudo sv up'
alias svDown='sudo sv down'
alias svRestart='sudo sv restart'
alias svStatus='sudo sv status'
alias svActive='sudo sv status /var/service/*'
alias svList='ls /etc/sv'

SV() {
  __usage__() {
    USAGE="SV [OPTIONS] <SERVICE>"
    OPT_1="-u | --start    |>   Start"
    OPT_2="-d | --kill     |>   Stop"
    OPT_4="-r | --restart  |>   Restart"
    OPT_3="-a | --init     |>   Activate"
    OPT_5="-x | --remove   |>   Deactivate"
    OPT_6="-s | --status   |>   Check activation status"
    OPT_7="-l | --list     |>   List all services"

    printf "\n::USAGE::\n%s\n  %s\n  %s\n  %s\n  %s\n  %s\n  %s\n  %s\n\n" \
      "$USAGE" "$OPT_1" "$OPT_2" "$OPT_3" "$OPT_4" "$OPT_5" "$OPT_6" "$OPT_7"

  }

  __ver3n__() { printf "%s\n" "1.0"; }

  __defaults__() {
    VERBOSE=true
    AVAILABLE=
    ACTIVATED=
    ENABLED=
    SERVICES="/etc/sv"
    LINKS="/var/service"

    #> Availability
    if [ -d "$SERVICES"/"$*" ]; then
      SERVICE="$SERVICES"/"$*"
      AVAILABLE=true
    fi

    #| Initialization
    if [ -L "$LINKS"/"$*" ]; then
      ACTIVATED=true
      LINK="$LINKS"/"$*"

      if _sv_ status "$LINK" | grep run >/dev/null 2>&1; then
        ENABLED=true
      fi

    fi
  }

  __status__() {
    if [ $VERBOSE ]; then
      if [ ! "$AVAILABLE" ]; then
        printf "[?]: %s\n" "$*"
      elif [ "$ACTIVATED" ]; then
        _sv_ status "$*"
      else
        printf "[!]: %s\n" "$*"
      fi
    fi
  }

  __list__() {
    printf "\n::%s SERVICES::\n" "AVAILABLE"
    ls -h --color=auto "$SERVICES"

    printf "\n::%s SERVICES::\n" "INITIALIZED"
    _sv_ status "$LINKS"/*
  }

  __init__() {
    if [ ! "$ACTIVATED" ] && [ "$AVAILABLE" ]; then
      #echo "SERVICE: $SERVICE LINK: $LINKS/$* *: $*"
      _ln_ --symbolic "$SERVICE" "$LINKS"/"$*"
      [ "$VERBOSE" ] && printf "Activated and enabled %s\n" "$*"
      return 0
    fi
  }

  __start__() {
    if [ ! "$AVAILABLE" ]; then
      [ "$VERBOSE" ] && printf "[?]: %s\n" "$*"
      return 1

    elif [ "$ACTIVATED" ]; then
      if [ ! "$ENABLED" ]; then
        _sv_ up "$*"
      fi

      [ "$VERBOSE" ] && __status__ "$*"

      return 0

    else
      __init__ "$*"
      return 0
    fi
  }

  __stop__() { [ "$ACTIVATED" ] && _sv_ down "$*"; }

  __restart__() { [ "$ACTIVATED" ] && _sv_ restart "$*"; }

  __remove__() {
    if [ "$ACTIVATED" ]; then
      _sv_ down "$*"

      if [ "$VERBOSE" ]; then
        _rm_ --verbose "$LINK"
      else
        _rm_ "$LINK"
      fi

      return 0
    fi
  }

  #| Default
  if [ "$#" -eq 0 ]; then
    __usage__
    __defaults__
    __list__
  fi

  #| Info
  VERBOSE=true
  case "$1" in
  -v | --version) __ver3n__ ;;
  -q | --quiet)
    shift
    VERBOSE=""
    ;;
  --verbose) shift ;;
  -h | --help) __usage__ ;;
  *) ;;
  esac

  #| Loop through action/service pairs
  while [ "$#" -ge 1 ]; do

    #| Actions
    case "$1" in
    "-u" | "--start")
      shift
      SV_CMD="__start__"
      ;;
    "-d" | "--kill")
      shift
      SV_CMD="__stop__"
      ;;
    "-r" | "--restart")
      shift
      SV_CMD="__restart__"
      ;;
    "-a" | "--init")
      shift
      SV_CMD="__init__"
      ;;
    "-x" | "--remove")
      shift
      SV_CMD="__remove__"
      ;;
    "-l" | "--list")
      shift
      SV_CMD="__list__"
      ;;
    "-s" | "--status")
      shift
      SV_CMD="__status__"
      ;;
    "-"*) shift ;;
    *) SV_CMD="__status__" ;;
    esac

    #| Defaults
    __defaults__ "$1"

    #| Services
    case "$1" in
    "-"*) ;;
    *)
      #| Skip blanks
      [ "$1" ] || return 1

      #| Perform action on service
      eval "$SV_CMD" "$1"

      #| Status after changes - Verbose
      #				[ "$VERBOSE" ] &&
      #					case "$SV_CMD" in
      #						*"list"*|*"status"*) ;;
      #						*) __status__ "$1" ;;
      #					esac
      #					;;
      ;;
    esac

    shift

  done

}

#> General
alias b='bash' B='clear;bash'
alias e='nvim' E='sudo nvim'
alias c='clear'
alias ls='ls -h --color=auto'
alias lsx='ls -1XB'
alias ll='ls -lv --group-directories-first'
alias lm='ll | more'
alias la='ll -A'
alias Logout='sudo pkill -KILL craole'
alias Reboot='sudo reboot'
