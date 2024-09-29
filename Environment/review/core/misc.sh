#!/bin/sh
# shellcheck disable=SC2034

QT_QPA_PLATFORMTHEME="gtk2" # Have QT use gtk2 theme.
MOZ_USE_XINPUT2="1"         # Mozilla smooth scrolling/touchpads.

# [ "$(sysINF --shell)" = "gitSH" ] &&
# MSYS=winsymlinks:nativestrict
