#!/usr/bin/env bash
#shellcheck disable=SC2329

usage() {
	cat <<EOF
Usage: ${0##*/} [OPTIONS] NAME

Find where a function, alias, builtin, or command is defined.

Options:
  -f, --func, --function     Show function location (file and line, if available)
  -a, --alias                Show where alias is defined (best effort)
  -c, --command              Show command path (using 'type' and 'whereis')
  -b, --builtin              Show if NAME is a shell builtin
  -A, --all                  Show all information
  -h, --help                 Show this help message

Examples:
  ${0##*/} -f myfunc
  ${0##*/} --alias ls
  ${0##*/} -A cd
EOF
}

echo "Usage: ${0##*/} [OPTIONS] NAME"
# shellcheck disable=SC2317
return >/dev/null 2>&1 || exit

mode="all"
name=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	-f | --func | --function)
		mode="func"
		shift
		;;
	-a | --alias)
		mode="alias"
		shift
		;;
	-c | --command)
		mode="command"
		shift
		;;
	-b | --builtin)
		mode="builtin"
		shift
		;;
	-A | --all)
		mode="all"
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		echo "Unknown option: $1" >&2
		usage
		exit 1
		;;
	*)
		name="$1"
		shift
		;;
	esac
done

if [[ -z "${name}" ]]; then
	echo "Error: NAME required." >&2
	usage
	exit 1
fi

found=0

show_func() {
	if declare -F "${name}" &>/dev/null; then
		echo "Function '${name}' is defined at:"
		# extdebug gives file and line number if available
		local loc
		loc=$(
			shopt -s extdebug
			declare -F "${name}"
			shopt -u extdebug
		)
		if [[ -n "${loc}" ]]; then
			echo "${loc}"
		else
			echo "Location info not available (possibly defined interactively)."
		fi
		found=1
	fi
}

show_alias() {
	if alias "${name}" &>/dev/null; then
		# Try to find the file where the alias is set
		echo "Alias '${name}' is defined as:"
		alias "${name}"
		# Try to find in known rc files
		local rcfile
		for rcfile in ~/.bashrc ~/.bash_profile ~/.profile ~/.zshrc ~/.kshrc; do
			if [[ -f "${rcfile}" ]] && grep -q "alias[[:space:]]\+${name}=" "${rcfile}"; then
				echo "Alias found in: ${rcfile}"
			fi
		done
		found=1
	fi
}

show_builtin() {
	case "$(type -t "${name}")" in
	builtin)
		echo "'${name}' is a shell builtin."
		found=1
		;;
	*) ;;
	esac
}

show_command() {
	case "$(type -t "${name}")" in
	file)
		echo "'${name}' is an external command:"
		type -a "${name}"
		if command -v whereis &>/dev/null; then
			whereis "${name}"
		fi
		found=1
		;;
	*) ;;
	esac
}

case "${mode}" in
func) show_func ;;
alias) show_alias ;;
builtin) show_builtin ;;
command) show_command ;;
all)
	show_func
	show_alias
	show_builtin
	show_command
	;;
*)
	echo "Invalid mode: ${mode}" >&2
	exit 1
	;;
esac

if [[ ${found} -eq 0 ]]; then
	echo "No function, alias, builtin, or command named '${name}' found."
	exit 2
fi
