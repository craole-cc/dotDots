#!/usr/bin/env bash

usage() {
	case "$1" in
		--option)
			printf "Error: %s requires an argument\n" "$2"
			;;
		*)
			printf "Usage: yt-download <url> [quality]\n"
			printf "Quality options: best, 1080p, 720p, 480p, audio\n"
			;;
	esac

	exit 1
}

#@ Set defaults
URL=""
FMT="1080p"
DIR=@downloads@
MOD=@module@
CFG=@config@
CMD=@ytdlp@/bin/yt-dlp

#@ Parse arguments
while [ "$#" -gt 0 ]; do
	case "$1" in
		-u | --url)
			[ -n "$2" ] || usage --option "$1"
			shift
			URL="$1"
			;;
		-f | --format)
			[ -n "$2" ] || usage --option "$1"
			shift
			FMT="$1"
			;;
		-d | --dir)
			[ -n "$2" ] || usage --option "$1"
			shift
			DIR="$1"
			;;
		-c | --config)
			[ -n "$2" ] || usage --option "$1"
			shift
			CFG="$1"
			;;
		-m | --module)
			[ -n "$2" ] || usage --option "$1"
			shift
			MOD="$1"
			;;
	esac
	shift
done

#@ Skip if no arguments are provided
[ -n "$URL" ] || usage >&2

#@ Create config if it doesn't exist or is out of date
mkdir -p "$(dirname "$CFG")"
cmp "$MOD" "$CFG" || cp -f "$MOD" "$CFG"

#@ Execute the command
case $FMT in
	"best")
		"$CMD" "$URL"
		;;
	"audio")
		"$CMD" --extract-audio --audio-format mp3 "$URL"
		;;
	*)
		"$CMD" \
			--config-location "$CFG" \
			--format "bestvideo[height<=${FMT%p}]+bestaudio/best[height<=${FMT%p}]" \
			--output "${DIR}/%(title)s.%(ext)s" \
			"$URL"
		;;
esac
