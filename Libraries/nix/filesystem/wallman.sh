#!/bin/sh
# Wallpaper Manager - Unified script for wallpaper classification and management
# Usage: wallman.sh <command> [options]

set -eu

#> Configuration (injected by Nix via substituteAll)
CFG_NAME="@name@"
CFG_RESOLUTION="@resolution@"
PATH_WALLPAPERS="@directory@"
PATH_CURRENT="@current@"

#> Tools (injected by Nix)
CMD_CONVERT="@cmdConvert@"
CMD_FD="@cmdFd@"
CMD_RG="@cmdRg@"
CMD_LN="@cmdLn@"
CMD_SHUF="@cmdShuf@"
CMD_REALPATH="@cmdRealpath@"

#> Cache files for different classification types
CACHE_POLARITY="@cachePolarity@"
CACHE_PURITY="@cachePurity@"
CACHE_CATEGORY="@cacheCategory@"
CACHE_FAVORITE="@cacheFavorite@"

#> Ensure cache directory exists
ensure_cache_dir() {
  mkdir -p "$(dirname "$CACHE_POLARITY")" 2> /dev/null || true
}

#> Classify image polarity (dark/light)
classify_polarity() {
  image="$1"

  if [ ! -f "$image" ]; then
    return 1
  fi

  #> Check cache first
  if [ -f "$CACHE_POLARITY" ]; then
    cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$image")\|" "$CACHE_POLARITY" 2> /dev/null | cut -d'|' -f2)
    if [ -n "$cached" ]; then
      printf "%s" "$cached"
      return 0
    fi
  fi

  #> Analyze using ImageMagick
  if command -v "$CMD_CONVERT" > /dev/null 2>&1; then
    brightness=$(
      "$CMD_CONVERT" "$image" -colorspace Gray -format "%[fx:mean*100]" info: 2> /dev/null \
        || printf "50"
    )
    brightness_int=$(printf "%.0f" "$brightness")

    if [ "$brightness_int" -lt 50 ]; then
      printf "dark"
    else
      printf "light"
    fi
  else
    #> Fallback to filename heuristic
    case "$(basename "$image")" in
      *dark* | *night* | *moon* | *shadow* | *black*)
        printf "dark"
        ;;
      *light* | *day* | *sun* | *bright* | *white*)
        printf "light"
        ;;
      *)
        printf "dark"
        ;;
    esac
  fi
}

#> Classify image purity (sfw/nsfw)
classify_purity() {
  image="$1"

  #> Check cache first
  if [ -f "$CACHE_PURITY" ]; then
    cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$image")\|" "$CACHE_PURITY" 2> /dev/null | cut -d'|' -f2)
    if [ -n "$cached" ]; then
      printf "%s" "$cached"
      return 0
    fi
  fi

  #> Filename heuristic for now (could be extended with ML)
  case "$(basename "$image")" in
    *nsfw* | *18+* | *adult*)
      printf "nsfw"
      ;;
    *)
      printf "sfw"
      ;;
  esac
}

#> Classify image category
classify_category() {
  image="$1"

  #> Check cache first
  if [ -f "$CACHE_CATEGORY" ]; then
    cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$image")\|" "$CACHE_CATEGORY" 2> /dev/null | cut -d'|' -f2)
    if [ -n "$cached" ]; then
      printf "%s" "$cached"
      return 0
    fi
  fi

  #> Filename heuristic (could be extended with ML)
  case "$(basename "$image")" in
    *nature* | *landscape* | *mountain* | *forest* | *ocean*)
      printf "nature"
      ;;
    *anime* | *manga* | *waifu*)
      printf "anime"
      ;;
    *abstract* | *geometric* | *pattern*)
      printf "abstract"
      ;;
    *city* | *urban* | *building*)
      printf "urban"
      ;;
    *)
      printf "uncategorized"
      ;;
  esac
}

#> Check if image is favorited
classify_favorite() {
  image="$1"

  if [ -f "$CACHE_FAVORITE" ]; then
    cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$image")\|" "$CACHE_FAVORITE" 2> /dev/null | cut -d'|' -f2)
    if [ -n "$cached" ]; then
      printf "%s" "$cached"
      return 0
    fi
  fi

  printf "false"
}

#> Scan directory and build cache
scan_directory() {
  classification_type="$1"
  cache_file="$2"

  if [ ! -d "$PATH_WALLPAPERS" ]; then
    printf "Error: Directory does not exist: %s\n" "$PATH_WALLPAPERS" >&2
    return 1
  fi

  ensure_cache_dir

  #> Create cache header
  printf "# %s classification cache for %s\n" "$classification_type" "$PATH_WALLPAPERS" > "$cache_file"
  printf "# Monitor: %s (%s)\n" "$CFG_NAME" "$CFG_RESOLUTION" >> "$cache_file"
  printf "# Generated: %s\n" "$(date)" >> "$cache_file"

  #> Scan and classify all images
  "$CMD_FD" -t f -e jpg -e png -e webp . "$PATH_WALLPAPERS" 2> /dev/null \
    | while read -r image; do
      case "$classification_type" in
        polarity)
          classification=$(classify_polarity "$image")
          ;;
        purity)
          classification=$(classify_purity "$image")
          ;;
        category)
          classification=$(classify_category "$image")
          ;;
        favorite)
          classification=$(classify_favorite "$image")
          ;;
        *)
          printf "Error: Unknown classification type: %s\n" "$classification_type" >&2
          return 1
          ;;
      esac
      printf "%s|%s\n" "$("$CMD_REALPATH" "$image")" "$classification" >> "$cache_file"
    done

  count=$("$CMD_RG" -c '|' "$cache_file" 2> /dev/null || printf "0")
  printf "Scanned and classified %s images (%s) in %s\n" "$count" "$classification_type" "$PATH_WALLPAPERS"
}

#> Get current wallpaper
get_current() {
  if [ -L "$PATH_CURRENT" ] && [ -e "$PATH_CURRENT" ]; then
    "$CMD_REALPATH" "$PATH_CURRENT"
  else
    printf "No wallpaper currently set for %s\n" "$CFG_NAME" >&2
    return 1
  fi
}

#> Set wallpaper based on filters
set_wallpaper() {
  #> Parse filter arguments
  polarity=""
  purity=""
  category=""
  favorite=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --polarity)
        polarity="$2"
        shift 2
        ;;
      --purity)
        purity="$2"
        shift 2
        ;;
      --category)
        category="$2"
        shift 2
        ;;
      --favorite)
        favorite="$2"
        shift 2
        ;;
      *)
        printf "Error: Unknown filter: %s\n" "$1" >&2
        return 1
        ;;
    esac
  done

  #> Start with all images
  candidates=$("$CMD_FD" -t f -e jpg -e png -e webp . "$PATH_WALLPAPERS" 2> /dev/null)

  #> Apply polarity filter
  if [ -n "$polarity" ]; then
    if [ ! -f "$CACHE_POLARITY" ]; then
      printf "Error: Polarity cache not found. Run 'classify --polarity' first.\n" >&2
      return 1
    fi
    candidates=$(printf "%s\n" "$candidates" | while read -r img; do
      cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$img")\|$polarity\$" "$CACHE_POLARITY" 2> /dev/null)
      [ -n "$cached" ] && printf "%s\n" "$img"
    done)
  fi

  #> Apply purity filter
  if [ -n "$purity" ]; then
    if [ ! -f "$CACHE_PURITY" ]; then
      printf "Error: Purity cache not found. Run 'classify --purity' first.\n" >&2
      return 1
    fi
    candidates=$(printf "%s\n" "$candidates" | while read -r img; do
      cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$img")\|$purity\$" "$CACHE_PURITY" 2> /dev/null)
      [ -n "$cached" ] && printf "%s\n" "$img"
    done)
  fi

  #> Apply category filter
  if [ -n "$category" ]; then
    if [ ! -f "$CACHE_CATEGORY" ]; then
      printf "Error: Category cache not found. Run 'classify --category' first.\n" >&2
      return 1
    fi
    candidates=$(printf "%s\n" "$candidates" | while read -r img; do
      cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$img")\|$category\$" "$CACHE_CATEGORY" 2> /dev/null)
      [ -n "$cached" ] && printf "%s\n" "$img"
    done)
  fi

  #> Apply favorite filter
  if [ -n "$favorite" ]; then
    if [ ! -f "$CACHE_FAVORITE" ]; then
      printf "Error: Favorite cache not found. Run 'classify --favorite' first.\n" >&2
      return 1
    fi
    candidates=$(printf "%s\n" "$candidates" | while read -r img; do
      cached=$("$CMD_RG" "^$("$CMD_REALPATH" "$img")\|$favorite\$" "$CACHE_FAVORITE" 2> /dev/null)
      [ -n "$cached" ] && printf "%s\n" "$img"
    done)
  fi

  #> Check if we have any candidates
  if [ -z "$candidates" ]; then
    printf "Error: No wallpapers match the specified filters\n" >&2
    return 1
  fi

  #> Select random wallpaper
  selected=$(printf "%s\n" "$candidates" | "$CMD_SHUF" -n 1)

  if [ ! -f "$selected" ]; then
    printf "Error: Selected wallpaper does not exist: %s\n" "$selected" >&2
    return 1
  fi

  #> Create symlink
  "$CMD_LN" -sf "$selected" "$PATH_CURRENT"
  printf "%s\n" "$selected"
}

#> Main command dispatcher
main() {
  if [ $# -lt 1 ]; then
    printf "Usage: %s <command> [options]\n" "$0" >&2
    printf "Commands:\n" >&2
    printf "  classify --polarity|--purity|--category|--favorite|--all\n" >&2
    printf "  get\n" >&2
    printf "  set [--polarity <dark|light>] [--purity <sfw|nsfw>] [--category <name>] [--favorite <true|false>]\n" >&2
    exit 1
  fi

  command="$1"
  shift

  case "$command" in
    classify)
      if [ $# -lt 1 ]; then
        printf "Error: classify requires a type flag\n" >&2
        exit 1
      fi

      case "$1" in
        --polarity)
          scan_directory "polarity" "$CACHE_POLARITY"
          ;;
        --purity)
          scan_directory "purity" "$CACHE_PURITY"
          ;;
        --category)
          scan_directory "category" "$CACHE_CATEGORY"
          ;;
        --favorite)
          scan_directory "favorite" "$CACHE_FAVORITE"
          ;;
        --all)
          scan_directory "polarity" "$CACHE_POLARITY"
          scan_directory "purity" "$CACHE_PURITY"
          scan_directory "category" "$CACHE_CATEGORY"
          scan_directory "favorite" "$CACHE_FAVORITE"
          ;;
        *)
          printf "Error: Unknown classification type: %s\n" "$1" >&2
          exit 1
          ;;
      esac
      ;;
    get)
      get_current
      ;;
    set)
      set_wallpaper "$@"
      ;;
    *)
      printf "Error: Unknown command: %s\n" "$command" >&2
      exit 1
      ;;
  esac
}

main "$@"
