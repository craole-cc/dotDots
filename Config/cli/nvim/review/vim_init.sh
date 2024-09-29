#!/bin/sh

set -o # ENV Export <Begin>
# ----------------------------------------------------------------------------
# Directories
nvim_DIR="$HOME/.config/nvim"
nvim_resources="$nvim_DIR/resources"
nvim_autoload="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/autoload
nvim_archive="$HOME/.cache/nvim/archive"
archive_NameFmt="$nvim_archive"/$(date +%-Y%-m%-d)-$(date +%-T)

# Files
vim_plug="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
plugINIT="$nvim_autoload/plug.vim"
nvim_plugRC="$nvim_resources/plugins.vim"
nvim_basicRC="$nvim_resources/basic.vim"
nvimRC="$nvim_DIR/init.vim"
# ------------------------------------------------------------------------------
set +o # ENV Export <End>

# Validate dependencies
Dependencies="p7zip neovim git curl ripgrep alacritty lf bat exa"
for Dependency in $Dependencies; do
    pacman --query --quiet | rg --quiet --word-regexp "$Dependency" ||
    sudo pacman \
    --sync \
    --refresh \
    --sysupgrade \
    --noconfirm \
    --quiet \
    --needed "$Dependency"
done

# Establish Plugins Environment
if [ -d "$nvim_autoload" ] ;then
    mkDIR --parents "$nvim_archive"
    tar -czvf "$archive_NameFmt"_autoload.tar.gz "$nvim_DIR"
    cd "$nvim_DIR/.." && rm --force --recursive "$nvim_autoload"
fi
    curl \
        --fail \
        --location \
        --output "$plugINIT" \
        --create-DIRs \
        "$vim_plug"

# Deploy NVIM Config Files
if [ -d "$nvim_DIR" ] ;then
    mkDIR --parents "$nvim_archive"
    tar -czvf "$archive_NameFmt".tar.gz "$nvim_DIR"
    cd "$nvim_DIR/.." && rm --force --recursive "$nvim_DIR"
fi
    mkDIR --parents "$nvim_DIR"

cat <<\EOF >>"$nvim_plugRC"
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-DIRs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $nvimRC
endif

call plug#begin(system('echo -n "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/autoload"'))

" Automatically install missing plugins on startup
if !empty(filter(copy(g:plugs), '!isDIRectory(v:val.DIR)'))
  autocmd VimEnter * PlugInstall | q
endif

" Plugins
    Plug 'tpope/vim-surround'
    Plug 'preservim/nerdtree'
    Plug 'junegunn/goyo.vim'
    Plug 'jreybert/vimagit'
    Plug 'lukesmithxyz/vimling'
    Plug 'vimwiki/vimwiki'
    Plug 'bling/vim-airline'
    Plug 'tpope/vim-commentary'
    Plug 'ap/vim-css-color'
call plug#end()
EOF

cat <<\EOF >>"$nvim_basicRC"
" Basic:
    set title
    set bg=light
    set go=a
    set mouse=a
    set nohlsearch
    set clipboard+=unnamedplus
    set noshowmode
    set noruler
    set laststatus=0
    set noshowcmd
	nnoremap c "_c
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
	set number relativenumber

" Enable autocompletion:
	set wildmode=longest,list,full

" Disable automatic commenting on newline:
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Perform dot commands over visual blocks:
	vnoremap . :normal .<CR>

" Goyo plugin makes text more readable when writing prose:
	map <leader>f :Goyo \| set bg=light \| set linebreak<CR>

" Spell-check set to <leader>o, 'o' for 'orthography':
	map <leader>o :setlocal spell! spelllang=en_us<CR>

" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
    set splitbelow splitright
EOF
# export PS1=">"