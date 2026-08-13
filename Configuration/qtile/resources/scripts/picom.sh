#!/bin/bash
#shellcheck enable=all
if pgrep -x "picom" >/dev/null; then
	pkill picom
else
	# picom -b --config ~/.config/qtile/scripts/picom.conf
	# picom --experimental-backends
	picom
fi
