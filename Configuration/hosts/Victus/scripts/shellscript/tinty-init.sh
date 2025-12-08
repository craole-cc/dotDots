#!/bin/sh
mkdir -p ~/.local/share/tinted-theming/tinty/themes
cd ~/.local/share/tinted-theming/tinty/themes || exit 1

# Link all your themes with proper prefixes
for theme in ~/Configuration/assets/themes/*.yaml; do
	basename=$(basename "$theme")
	# Check if it's base16 or base24
	if grep -q 'system: "base16"' "$theme"; then
		prefix="base16-"
	elif grep -q 'system: "base24"' "$theme"; then
		prefix="base24-"
	else
		prefix=""
	fi

	# Only link if not already prefixed
	case "$basename" in
	base16-* | base24-*)
		ln -sf "$theme" "$basename"
		;;
	*)
		ln -sf "$theme" "${prefix}${basename}"
		;;
	esac
done
