#! /bin/sh

#==================================================
#
# _nvim
# Linux/CLI/environment/app/nvim.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

# DIRS
_nvim_LOCAL="$HOME/.config/nvim"
_nvim_DOTS="${CONFIG_HOME:-?}/nvim"
_nvim_RESOURCES="$_nvim_DOTS/resources"
_nvim_PLUGINS="$_nvim_DOTS/plugins"
_vim_PLUG_DIR="$_nvim_PLUGINS/autoload"

# CONFIG
_nvim_CACHE="$CACHE_HOME/nvim"
_nvim_CONFIG="$_nvim_DOTS/init.vim"
_vim_PLUG="$_vim_PLUG_DIR/plug.vim"

# RESOURCES

#> Install <#
if ! weHave nvim; then
    if weHave paru; then
        Pin neovim
    elif weHave choco; then
        choco install neovim
    fi
fi

#> Verify Instalation <#
weHave nvim || return
"$NeedForSpeed" || weHave --report version nvim >>"$DOTS_loaded_apps"

#> Establish Link in HOME
if [ ! -L "$_nvim_LOCAL" ]; then
    rm -rf "$_nvim_LOCAL"
    ln \
        --symbolic \
        --force \
        "$_nvim_DOTS" \
        "$_nvim_LOCAL"
fi

#> Plugin Manager <#
if [ ! -f "$_vim_PLUG" ]; then
    curl \
        --fail \
        --location \
        --output "${_vim_PLUG}" \
        --create-dirs \
        'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    sudo chmod +rwx "$_vim_PLUG_DIR"
fi

alias vim='nvim'
alias v='vim'
alias V='sudo vim'

# --> Edit Config
CFG_nvim() {
    nvim "$_nvim_CONFIG"
}

# __________________________________________ EXEC<|
