#! /bin/sh
# shellcheck disable=SC2154

#==================================================
#
# EMOJIFY
#
#==================================================

# _________________________________ DOCUMENTATION<|

#? https://github.com/mrowa44/emojify

# _________________________________________ LOCAL<|

emojifyCMD="$DOTS_BIN_IMPORT/emojify"

if [ ! -f "$emojifyCMD" ]; then
    curl \
        --url https://raw.githubusercontent.com/mrowa44/emojify/master/emojify \
        --output "$emojifyCMD"
    chmod +x "$emojifyCMD"
fi


emo() {
    for emoji in "$@"; do
        emojify --list | grep "$emoji"
    done
}

emos() {
    emojify --list |
        bat \
            --theme="Solarized (dark)" \
            --line-range 4: \
            --plain
}

alias emote='emojify'

unset emojifyCMD
