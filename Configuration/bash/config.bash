#!/usr/bin/env bash

#@ Only execute this script for interactive shells
case "$BASHOPTS" in
*i*)
	#@ Add the bin directory to the path
	PATH="$(pathman --append "$SHELL_HOME/bin" --print)" export PATH

	#@ Load resources and functions
	mod.init "$SHELL_HOME/bin"
	mod.init "$SHELL_HOME/modules"
	# init_prompt
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
