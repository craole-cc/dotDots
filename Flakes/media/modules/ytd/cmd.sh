#!/usr/bin/env bash

if [ -z "$1" ]; then
	printf "Usage: yt-download <url> [quality]\n"
	printf "Quality options: best, 1080p, 720p, 480p, audio\n"
	exit 1
fi

URL="$1"
QUALITY="${2:-1080p}"
DIR="${3:-@videos@}"

case $QUALITY in
	"best")
		@ytdlp@/bin/yt-dlp "$URL"
		;;
	"audio")
		@ytdlp@/bin/yt-dlp -x --audio-format mp3 "$URL"
		;;
	*)
		@ytdlp@/bin/yt-dlp \
			-f "bestvideo[height<=${QUALITY%p}]+bestaudio/best[height<=${QUALITY%p}]" \
			-o "$DIR/%(title)s.%(ext)s" \
			"$URL"
		;;
esac
