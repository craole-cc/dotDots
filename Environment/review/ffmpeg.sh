#! /bin/sh

#> Install <#
if ! weHave lame; then
    if weHave paru; then
        Pin lame ffmpeg
    elif weHave choco; then
        choco install lame
    elif weHave winget; then
        winget install lame
    else
        cargo install lame
    fi
fi

#> Verify Instalation <#
# if weHave lame; then
#     {
#         ver lame
#         ver ffmpeg
#     } >>"$DOTS_loaded_apps"
# else
#     return
# fi

mp4tomp3_constant() {
    for mp4 in "$@"; do
        ffmpeg -i "$mp4" -vn \
            -acodec libmp3lame -ac 2 -ab 160k -ar 48000 \
            audio.mp3
    done
}
mp4tomp3_variable() {
    for mp4 in "$@"; do
        ffmpeg -i "$mp4" -vn \
            -acodec libmp3lame -ac 2 -qscale:a 4 -ar 48000 \
            audio.mp3
    done
}
