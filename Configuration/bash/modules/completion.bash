#!/usr/bin/env bash
#==================================================
#
# CONFIG - COMPLETION
# CLI/config/bash/resources/completion.bash
#
#==================================================

# _______________________________________ OPTIONS<|

if [ -r /usr/share/bash-completion/bash_completion ]; then
	BASH_COMPLETION="/usr/share/bash-completion/bash_completion"
elif [ -r /etc/bash_completion ]; then
	BASH_COMPLETION="/etc/bash_completion"
fi

rustup --version > /dev/null 2>&1 \
	&& rustup completions bash > "$DOTS_BASH/scripts/rustup.bash"

#@ Use bash-completion, if available
shopt -oq posix || {
	[ -n "$PS1" ] && [ -f "$BASH_COMPLETION" ] && . "$BASH_COMPLETION"
}
