#! /bin/sh

#==================================================
#
# GETOPTS_LONG
#
#==================================================

# _________________________________ DOCUMENTATION<|

#? https://github.com/alan1world/yt_chapters

# _________________________________________ LOCAL<|

ytChapDIR="${DOTS_DOWN:?}/yt_chapters"
ytChapSRC="${DOTS_DOWN:?}/yt_chapters/yt_chapters"
ytChapLNK="${DOTS_BIN_IMPORT:?}/yt_chapters"

if [ ! -d "$ytChapDIR" ]; then
    updateGitUtils
fi

#> Establish Link in BIN
if [ -f "$ytChapSRC" ]; then
    ln \
        --symbolic \
        --force \
        "$ytChapSRC" \
        "$ytChapLNK"
else
    echo "$ytChapSRC" not found
fi

#> Install <#
# if ! weHave ffmpeg; then
#     if weHave paru; then
#         Pin ffmpeg
#     elif weHave choco; then
#         cup ffmpeg -y
#     elif weHave winget; then
#         winget install ffmpeg
#     fi
# fi

#> Verify Instalation <#
# weHave yt_chapters || return

# _______________________________________ EXPORT<|

#> Activate Aliases <#
alias ytc='yt_chapters --split'
alias ytcT='yt_chapters --test'

# unset ytChapDIR ytChapSRC ytChapLNK
