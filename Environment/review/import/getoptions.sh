#! /bin/sh

#==================================================
#
# GETOPTOPTIONS
#
#==================================================

# _________________________________ DOCUMENTATION<|

#? https://github.com/ko1nksm/getoptions.git

# _________________________________________ LOCAL<|

G__O="$DOTS_BIN_IMPORT/getoptions"
genG__O="$DOTS_BIN_IMPORT/gengetoptions"

__update__() {
    #|  Download
    wget https://github.com/ko1nksm/getoptions/releases/latest/download/getoptions --output-document="$G__O"
    wget https://github.com/ko1nksm/getoptions/releases/latest/download/getoptions --output-document="$genG__O"

    #| Initialize
    chmod +x "$G__O" "$genG__O"
}

if
    [ ! -f "$G__O" ] || [ ! -f "$genG__O" ]
then
    __update__
fi

unset G__O genG__O
