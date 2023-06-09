#! /bin/sh
# shellcheck disable=SC2034

#> Default Apps
#@ ./Environment/core/apps.sh

# ===================================================================
#@                        TERMINAL_EMULATOR                        @#
# ===================================================================

terminal_emulator() {

  _preferred_terminal="kitty"
  _fallback_terminal="alacritty"

  if weHave "$_preferred_terminal"; then
    TERMINAL_EMULATOR="$_preferred_terminal"
  elif weHave "$_fallback_terminal"; then
    TERMINAL_EMULATOR="$_fallback_terminal"
  fi

  TERM="xterm-256color"
  COLORTERM="truecolor"
}

terminal_emulator

# ===================================================================
#@		                           EDITOR			                       @#
# ===================================================================

_code_editor() {

  if weHave code-oss; then
    VISUAL=code-oss
  elif weHave code; then
    VISUAL=code
  fi

  if weHave nvim; then
    EDITOR=nvim
  elif weHave vim; then
    EDITOR=vim
  elif weHave nano; then
    EDITOR=nano
  fi

  EDITOR_ROOT="sudo notepadqq --allow-root"

  weHave "$EDITOR_ROOT" || EDITOR_ROOT="sudo $EDITOR"

  alias e='$EDITOR'
  alias E='$EDITOR_ROOT'

  [ "$TERM_PROGRAM" = "vscode" ] && NeedForSpeed=true
}

_code_editor

# ===================================================================
#@		                            PAGER			                       @#
# ===================================================================

_pager() {
  LESS=-R
  LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
  LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
  LESS_TERMCAP_me="$(printf '%b' '[0m')"
  LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
  LESS_TERMCAP_se="$(printf '%b' '[0m')"
  LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
  LESS_TERMCAP_ue="$(printf '%b' '[0m')"
  LESSOPEN="| /usr/bin/highlight -O ansi %s 2>/dev/null"

  # weHave bat && PAGER='bat --force-colorization'
  # weHave vim && PAGER="vim -u $DOTS/Config/cli/vim/more.vim -"
  weHave less && PAGER='less'
}

_manpager() {
  if weHave vim; then
    MANPAGER='sh -c "vim -MRn \
    -c \"set \
        buftype=nofile  \
        showtabline=0  \
        ft=man  \
        ts=8  \
        nomod  \
        nolist  \
        norelativenumber  \
        nonu  \
        noma \
      \" \
    -c \"normal L\" \
    -c \"nmap q :qa<CR>\" </dev/tty <(col -b)"'
  elif weHave bat; then
    MANPAGER="sh -c 'col -bx | bat -l man -p'"
  fi
}

_pager
_manpager

# ===================================================================
#@		                         FILE MANAGER 			                 @#
# ===================================================================

_file_manager() {
  _preferred_filemanager="doublecmd"
  _fallback_filemanager="lf"

  FILE_MANAGER="$_preferred_filemanager"
  weHave $FILE_MANAGER || FILE_MANAGER="$_fallback_filemanager"

  FILE_MANAGER_ROOT="sudo $FILE_MANAGER"

  alias fm='$FILE_MANAGER'
  alias FM='$FILE_MANAGER_ROOT'
}

_file_manager

# ===================================================================
#@		                            BROWSER    			                 @#
# ===================================================================

_web_browser() {

  _preferred_browser="firefox"
  _fallback_browser="brave"

  BROWSER="$_preferred_browser"
  weHave $BROWSER || BROWSER="$_fallback_browser"

  alias b='$BROWSER'
}

_web_browser

# ===================================================================
#@		                            MAIL      			                 @#
# ===================================================================

_email_client() {
  _preferred_client="thunderbird"
  _fallback_client="mutt"

  MAIL="$_preferred_client"
  weHave $MAIL || MAIL="$_fallback_client"

  alias @='$MAIL'
}

_email_client

# ===================================================================
#@		                        DOCUMENT VIEWER			                 @#
# ===================================================================

_doc_viewer() {
  _preferred_reader="mupdf"
  _fallback_reader="zathura"

  READER="$_preferred_reader"
  weHave $READER || READER="$_fallback_reader"

  alias r='$READER'
}

_doc_viewer

# ===================================================================
#@		                        SYSTEM VIEWER 			                 @#
# ===================================================================

_sys_viewer() {
  weHave htop && alias top='htop'
  weHave ytop && alias top='ytop'
  weHave gotop && alias top='gotop'
  weHave btm && alias top='btm'
  weHave btop && alias top='btop'
  weHave bpytop && alias top='bpytop'
}

_sys_viewer

# ===================================================================
#@		                          SYSTEM INFO 			                 @#
# ===================================================================
_fetch() {
  # weHave sysINF && alias fetch='sysINF'
  weHave neofetch && alias fetch='neofetch'
  weHave paleofetch && alias fetch='paleofetch'
  weHave bfetch && alias fetch='bfetch'
  weHave ufetch && alias fetch='ufetch'
  weHave macchina && alias fetch='macchina'
  weHave fastfetch && alias fetch='fastfetch'
}

_fetch

# ===================================================================
#@		                       PACKAGE MANAGER			                 @#
# ===================================================================
_pacman() {
  weHave choco && alias pm='choco'
  weHave apt-get && alias pm='sudo apt-get'
  weHave pacman && alias pm='sudo pacman'
  weHave yay && alias pm='yay'
  weHave paru && alias pm='paru'
}

_pacman

# ===================================================================
#@		                        TRADE VIEWER 			                 @#
# ===================================================================

_trading_charts() {
  weHave cointop && alias btc='cointop'
  weHave tradingview && alias charts='tradingview'
}

_trading_charts

# ===================================================================
#@		                          COMPOSITOR  			                 @#
# ===================================================================

COMPOSITOR=Picom

#@ _______________________________________________ DOTS_loaded_apps<|

#| reset AppList
# shellcheck disable=SC2154
rm -f "$DOTS_loaded_apps"
DOTS_loaded_apps() {
  "$NeedForSpeed" || sortby --row "$DOTS_loaded_apps"
}
