#!/bin/sh
# shellcheck enable=all
# Symlinks yazi config from dots into ~/.config/yazi
# Safe to re-run; all operations are idempotent

YAZI_CONF="${DOTS}/Configuration/yazi"
YAZI_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"

[ -d "$YAZI_CONF" ] || return 0

mkdir -p "$YAZI_HOME"

# config.toml → yazi.toml (yazi expects this name)
[ -f "$YAZI_CONF/config.toml" ] &&
	ln -sf "$YAZI_CONF/config.toml" "$YAZI_HOME/yazi.toml"

# Standard named files symlinked as-is
for f in keymap.toml theme.toml init.lua; do
	[ -f "$YAZI_CONF/$f" ] && ln -sf "$YAZI_CONF/$f" "$YAZI_HOME/$f"
done

# Plugins — each subdir becomes a plugin
if [ -d "$YAZI_CONF/plugins" ]; then
	mkdir -p "$YAZI_HOME/plugins"
	for plugin_dir in "$YAZI_CONF/plugins"/*/; do
		[ -d "$plugin_dir" ] || continue
		plugin_name="$(basename "$plugin_dir")"
		mkdir -p "$YAZI_HOME/plugins/$plugin_name"
		for lua in "$plugin_dir"*.lua; do
			[ -f "$lua" ] && ln -sf "$lua" "$YAZI_HOME/plugins/$plugin_name/$(basename "$lua")"
		done
	done
fi

[ -n "${VERBOSE:-}" ] && printf "yazi: config linked from %s\n" "$YAZI_CONF"
