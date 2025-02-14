#!/usr/bin/env bash

update_dots_path() {
	#@ Get the base directory
	BASE_DIR="$1"

	#@ Define exclusion patterns at the top level for reusability
	EXCLUDE_PATTERNS="review temp tmp archive backup"
	unset exclude_args pattern

	#@ Create temporary file securely
	TMP_FILE=$(mktemp)
	trap 'rm -f "$TMP_FILE"' EXIT

	if command -v fd > /dev/null 2>&1; then
		#@ Convert patterns to fd --exclude args
		for pattern in $EXCLUDE_PATTERNS; do
			exclude_args="$exclude_args --exclude '$pattern'"
		done

		#@ Store fd command and options
		find_cmd="fd ."
		find_opt="--type d $exclude_args"
	else
		#@ Convert patterns to find -iname args
		for pattern in $EXCLUDE_PATTERNS; do
			[ -n "$find_pattern" ] && find_pattern="$find_pattern -o"
			find_pattern="$find_pattern -iname '$pattern'"
		done

		#@ Store fd command and options
		find_cmd="find"
		find_opt="-type d \( $find_pattern \) -prune -o -type d -print"
	fi

	#@ Build find/fd command with dynamic exclusion patterns
	#@ eval is necessary here for POSIX compliance since arrays aren't available
	#@ and we need to construct a complex command with multiple patterns.
	#@ This is safe since EXCLUDE_PATTERNS is defined within the script.
	eval "$find_cmd" "$BASE_DIR" "$find_opt" > "$TMP_FILE"

	# @Include base dir first if it exists and isn't excluded
	case ":$PATH:" in
		":$BASE_DIR:") ;;
		*) temp_path="${PATH}:${BASE_DIR}" ;;
	esac

	#@ Build updated path
	while IFS= read -r dir; do
		case ":$temp_path:" in
			":$dir:") ;;
			*) temp_path="${temp_path}:${dir}" ;;
		esac
	done < "$TMP_FILE"

	#@ Update the PATH variable
	PATH="$temp_path"
	export PATH
}
