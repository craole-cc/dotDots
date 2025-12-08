#!/bin/sh
# toggle-theme - Switch between light and dark themes

if ! command -v tinty >/dev/null 2>&1; then
	printf 'Error: tinty not found\n' >&2
	exit 1
fi

# Get current theme
CURRENT=$(tinty current 2>/dev/null)

case "$CURRENT" in
*light*)
	printf 'Switching to dark mode...\n'
	tinty apply base24-bluloco-dark
	;;
*)
	printf 'Switching to light mode...\n'
	tinty apply base24-bluloco-light
	;;
esac

# Sync all apps to the new theme
sync-themes

printf 'Theme toggled successfully!\n'
