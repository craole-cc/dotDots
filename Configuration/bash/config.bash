#!/usr/bin/env bash

init_config() {
	conf_files="$(find "$1" -type f)"

	for conf in $conf_files; do
		# if [[ "$conf" =~ \.bash$ ]]; then
		if [ -r "$conf" ]; then
			# time . "$conf"
			. "$conf"
		else
			printf "File not readable:  %s\n" "$conf"
		fi
	done
}

#@ Only execute this script for interactive shells
case "$BASHOPTS" in
*i*)
	#@ Load resources and functions
	init_config "$SHELL_HOME/bin"
	init_config "$SHELL_HOME/modules"

	# update_dots_path "$DOTS/Bin" #TODO: Move to dotrc
	# update_dots_path "$SHELL_HOME/bin"
	init_prompt
	# init_fasfetch
	;;
*)
	# If this is a login shell, exit instead of returning
	# to ensure that the shell is completely closed.
	if shopt -q login_shell; then
		exit
	else
		return
	fi
	;;
esac
