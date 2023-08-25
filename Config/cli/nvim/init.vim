" ==================================================

" NVIMRC

" ==================================================

" _________________________________ DOCUMENTATION<|

" This INIT file loads modules and plugins.

" _____________________________________ RESOURCES<|

" --> Basic
source $NVIM_RESOURCES/basic.vim

" --> Plugins
call plug#begin()
Plug 'https://github.com/vim-airline/vim-airline'
call plug#end()

" source $NVIM_RESOURCES/plugin.vim
source $NVIM_RESOURCES/autoreload-files.vim

" --> Additional Features
source $NVIM_RESOURCES/html-text-object-linewise.vim
source $NVIM_RESOURCES/open-file-on-last-position.vim
source $NVIM_RESOURCES/search-match-blink.vim
source $NVIM_RESOURCES/trim-trailing-whitespace.vim

" -> Mappings and Abbreviations
source $NVIM_RESOURCES/abbreviations.vim
source $NVIM_RESOURCES/mappings.vim

:scriptnames