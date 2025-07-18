#!/bin/sh

main() {
  set_defaults
  parse_arguments "$@"
  execute_command
}

usage() {
  case "$1" in
  --option)
    printf "Error: %s requires an argument\n" "$2"
    ;;
  *)
    printf "Usage: yt-download [-u url] [-f format] [-d dir] [-c config] [-m module]\n"
    printf "Options:\n"
    printf "  -u, --url <url>         URL of the video to download\n"
    printf "  -f, --format <format>   Format of the video (best, 1080p, 720p, 480p, audio)\n"
    printf "  -d, --dir <dir>         Directory to save the video in\n"
    printf "  -c, --config <config>   Path to the yt-dlp config file\n"
    printf "  -m, --module <module>   Path to the yt-dlp module\n"
    ;;
  esac

  exit 1
}

set_defaults() {
  #{ Set defaults
  URL=""
  FMT=@fmt@
  DIR=@dls@
  MOD=@mod@
  CFG=@cfg@
  CMD=@cmd@
}

#{ Parse arguments
parse_arguments() {
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
    *)
      URL="$1"
      ;;
    esac
    shift
  done

}

execute_command() {
  #{ Skip if no arguments are provided
  [ -n "${URL}" ] || usage >&2

  #{ Create directories
  mkdir -p "${DIR}"
  mkdir -p "$(dirname "${CFG}")"

  #{ Create config if it doesn't exist or is out of date
  cmp "${MOD}" "${CFG}" || cp -f "${MOD}" "${CFG}"

  #{ Execute the command
  case "${FMT}" in
  "best")
    "${CMD}" "${URL}"
    ;;
  "audio")
    "${CMD}" --extract-audio --audio-format mp3 "${URL}"
    ;;
  *)
    "${CMD}" \
      --format "bestvideo[height<=${FMT%p}]+bestaudio/best[height<=${FMT%p}]" \
      --output "${DIR}/%(title)s.%(ext)s" \
      --config-location "${CFG}" \
      "${URL}"
    ;;
  esac
}

main "$@"
