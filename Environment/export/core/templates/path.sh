#!/bin/sh

#===============================================================
#
# PATH VARIABLES
# CLI/bin/environment/admin/path.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# export PATH="$HOME/.cabal/bin:$PATH"

# >>= Enable PATH manager =<< #
# . manENV.sh

# >>= Default =<< #
# _path PATH "$HOME"/.cabal/bin
# _path_ PATH "$HOME"/.local/bin
# _remove PATH ~/.local/bin
# _remove PATH /var/lib/flatpak/exports/bin

# PATH=$PATH$(
# fd \
# 	--full-path "$DOTshell" \
# 	--type d \
# 	--hidden \
# 	--exclude archive \
# ":%p" \
# )

# 	fd \
# 		--full-path "$DOTshell" \
# 		--type d \
# 		--hidden \
# 		--exclude *archive* \
# 		--exclude *cache* \

# 	":%p" \
# 	)

# fd \
# 	--full-path "${DOTshell:?}" \
# 	--type f \
# 	--hidden \
# 	--show-errors \
# 	--changed-within 3hrs \
# 	--exclude ./*archive* \
# 	--exclude ./*cache* \
# 	--exclude ./*tmp*

# >>= Print Updated PATH =<< #
# _pathlist
