#!/bin/sh

QUAKE_ID="foot-quake"
SHORTCUT_MIN="Window Minimize"
SHORTCUT_RAISE="Window Raise"

toggle_quake() {
	#> Activate via task manager walk or activation (focus first)
	qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "Activate Window Demanding Attention"
	sleep 0.1 # Brief settle

	#> Check if minimized (indirect via kdotool if available, or assume toggle)
	if pidof foot >/dev/null 2>&1; then
		#> Focus & raise
		qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "$SHORTCUT_RAISE"
	else
		#> Spawn if not running
		feet --app-id="$QUAKE_ID" &
		sleep 0.5
	fi

	#> Minimize if visible/active
	qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "$SHORTCUT_MIN"
}
