#!/bin/sh
#shellcheck enable=all

nircmd shortcut "${LOCALAPPDATA:?}/Microsoft/WindowsApps/wt.exe" "${APPDATA:?}/Microsoft/Windows/Start Menu/Programs/Startup" "WindowTerminal_Quake" "-w _quake" "" min
