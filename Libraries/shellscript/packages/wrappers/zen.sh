#!/bin/sh
#~@ Universal Zen Browser Launcher
#? Opens zen-twilight if available, zen-beta if not, falls back to $BROWSER

has_cmd() { command -v "$1" >/dev/null 2>&1; }

if has_cmd zen-twilight; then
	exec zen-twilight "$@"
elif has_cmd zen-beta; then
	exec zen-beta "$@"
elif has_cmd zen; then
	exec zen "$@"
elif [ -n "${BROWSER:-}" ] && has_cmd "$BROWSER"; then
	exec "$BROWSER" "$@"
else
	printf "zen: no browser found (zen-twilight, zen-beta, zen, or \$BROWSER)" >&2
	exit 1
fi
