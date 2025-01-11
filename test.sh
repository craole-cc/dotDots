#!/bin/sh

find_dotsrc() {
  rc="${1:-.dotsrc}" # Default to .dotsrc if not specified
  dots="$2"

  # If dots directory is explicitly provided, use it
  if [ -n "$dots" ]; then
    echo "$dots"
    return 0
  fi

  # Check root paths based on OS
  case "$(uname)" in
  "Darwin")
    start_paths="/Volumes /Users"
    ;;
  "Linux")
    start_paths="/mnt /media /home /"
    ;;
  "MINGW"* | "MSYS"* | "CYGWIN"*)
    start_paths="/" # Will catch all mounted drives in Windows
    ;;
  *)
    start_paths="/"
    ;;
  esac

  # Use find to search for rc file, limiting depth to avoid excessive recursion
  # Stop at first match using -quit (GNU find) or head -1 as fallback
  for start_path in $start_paths; do
    [ ! -d "$start_path" ] && continue

    result=$(find "$start_path" -maxdepth 6 -type f -name "$rc" -print 2>/dev/null | head -n 1)
    if [ -n "$result" ]; then
      dirname "$result"
      return 0
    fi
  done

  # Fallback to current script directory if no rc file found
  currdir=$(dirname "$0")
  cd "$currdir" >/dev/null 2>&1 && pwd || {
    echo "Error: Could not determine current directory" >&2
    return 1
  }
}

# Set DOTS variable using the find_dotsrc function
DOTS=$(find_dotsrc "$rc" "$dots") || {
  echo "Error: Could not determine DOTS directory" >&2
  return 1
}
