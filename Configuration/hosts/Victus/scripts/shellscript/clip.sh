#!/bin/sh

# Read from argument or stdin
if [ -n "$1" ]; then
    text="$1"
elif [ ! -t 0 ]; then
    # stdin is redirected (piped input)
    text="$(cat)"
else
    printf "Error: No text provided. Pass a string argument or pipe input.\n" >&2
    exit 1
fi

# Exit if text is empty
if [ -z "$text" ]; then
    printf "Error: No text provided. Pass a string argument or pipe input.\n" >&2
    exit 1
fi

# Detect OS and copy to clipboard
case "$(uname -s)" in
    Darwin)
        # macOS
        printf "%s" "$text" | pbcopy
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Windows (Git Bash, Cygwin, etc.)
        printf "%s" "$text" | clip.exe
        ;;
    *)
        # Linux - try wayland then X11
        if command -v wl-copy > /dev/null 2>&1; then
            printf "%s" "$text" | wl-copy
        elif command -v xsel > /dev/null 2>&1; then
            printf "%s" "$text" | xsel --clipboard --input
        elif command -v xclip > /dev/null 2>&1; then
            printf "%s" "$text" | xclip -selection clipboard
        else
            printf "Error: No clipboard utility found (install wl-copy, xsel, or xclip)\n" >&2
            exit 1
        fi
        ;;
esac

exit 0