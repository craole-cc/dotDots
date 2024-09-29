#! /bin/sh

#==================================================
# LSD
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|
lsdTUX="$XDG_CONFIG_HOME/lsd"
lsdWIN="$WIN_CONFIG_HOME/lsd"
lsdDOTS="${dotCLI:?}/lsd"
lsdDATA="$WIN_APPDATA/lsd"

lsdCFG="$lsdDOTS/config.yml"
lsdCFG_WIN="$lsdWIN/config.yml"

# Disable in Windows
[ "$sys_TYPE" = "Windows" ] && return

#> Install <#
weHave lsd || cargoInstall lsd

#> Verify Instalation <#
weHave lsd || return
"$NeedForSpeed" || weHave --report version lsd >>"$DOTS_loaded_apps"

# * Activate Aliases *#
LSD() {
  lsd --human-readable --almost-all --long --date relative --group-dirs first --blocks permission --blocks size --blocks date --blocks name --config-file "$lsdCFG"
  "$@"
}

alias ls="lsd --group-dirs first"
alias la="ls --almost-all"
alias ll='LSD'
alias lst="lsd --tree"
alias lsT="LSD --tree"
