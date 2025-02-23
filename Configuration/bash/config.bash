#!/usr/bin/env bash

#@ Only execute this script for interactive shells
case "$BASHOPTS" in !*i*) if shopt -q login_shell; then
	exit
else
	return
fi ;; esac

#@ Add the bin directory to the path
# PATH="$(pathman --append "$SHELL_HOME/bin" --print)" export PATH

#@ Define a list of files to include
include_files=(
	"$SHELL_HOME/modules"
	# "$SHELL_HOME/modules/**/*.bash"
)

#@ Define a list of files to exclude
exclude_files=(
	"$SHELL_HOME/scripts/rustup.bash"
	# "$SHELL_HOME/modules/exclude.bash"
)

#@ Process the list of files to include
module_files=()
for file in "${include_files[@]}"; do
	if [ "${COMMAND_FD:-}" ] || command -v fd >/dev/null 2>&1; then
		mapfile -t found_files < <(fd . "$file" --type file --exclude "${exclude_files[@]}")
	else
		mapfile -t found_files < <(find "$file" -type f |
			grep -v -F -x -f <(printf "%s\n" "${exclude_files[@]}"))
	fi
	module_files+=("${found_files[@]}")
done

#@ Load modules
for module in "${module_files[@]}"; do
	if [ -r "$module" ]; then
		result="$(. "$module")"
		. "$module"
	else
		printf "Module not readable:  %s\n" "$module"
	fi
done

init_prompt
# init_fasfetch

[ "$COMMAND_GIT" ] && echo "We have git"
[ "$COMMAND_RUSTUP" ] && echo "We have rustup"
[ "$COMMAND_FASTFETCH" ] && echo "We have fastfetch"
[ "$COMMAND_CURL" ] && echo "We have curl"

#@ Clean up
unset module_files module
