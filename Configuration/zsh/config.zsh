#!/bin/sh
# shellcheck disable=SC1090
#==================================================
#
# ASHRC
# /cli/zsh/.zshrc
#
#==================================================

RESOURCES="$ZDOTDIR/resources"
[ -d "$RESOURCES" ] || return 1

for resource in "$RESOURCES"/*.*; do
	if [ -r "$resource" ]; then
		. "$resource"
	fi
done

unset RESOURCES resource
# source /home/craole/.config/broot/launcher/bash/br

source C:\Users\Administrator\AppData\Roaming\dystroy\broot\config\launcher\bash\br
