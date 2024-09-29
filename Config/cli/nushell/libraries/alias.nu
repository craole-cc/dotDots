#
# ~/.config/nushell/scripts/aliases.nu
#

# Lazydocker
# https://github.com/jesseduffield/lazydocker
export alias lzd = lazydocker

# Lazygit
# https://github.com/jesseduffield/lazygit
export alias lzg = lazygit

# ls
export alias ll = ls --long
export alias la = ls --all
# export alias lls = ls --all --du
# export alias llss = lls | sort-by size
# export alias llsi = ls --all  | sort-by name i

# NPM
export alias npci = npm ci
export alias npi = npm install
export alias npr = npm run
export alias npv = npm version

#| exa
export alias exa	= exa --icons --all
export alias exal	= exa --long
export alias exat	= exa --tree
