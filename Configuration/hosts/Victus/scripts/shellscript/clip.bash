#!/usr/bin/env bash

# Read from argument or stdin
if [ -n "$1" ]; then
    text="$1"
elif [ ! -t 0 ]; then
    # stdin is redirected (piped input)
    text="$(cat)"
else
    echo "Error: No text provided. Pass a string argument or pipe input." >&2
    exit 1
fi

# Exit if text is empty
if [ -z "$text" ]; then
    echo "Error: No text provided. Pass a string argument or pipe input." >&2
    exit 1
fi

# Detect OS and copy to clipboard
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -n "$text" | pbcopy
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash, Cygwin, etc.)
    echo -n "$text" | clip.exe
else
    # Linux - try wayland then X11
    if command -v wl-copy &> /dev/null; then
        echo -n "$text" | wl-copy
    elif command -v xsel &> /dev/null; then
        echo -n "$text" | xsel --clipboard --input
    elif command -v xclip &> /dev/null; then
        echo -n "$text" | xclip -selection clipboard
    else
        echo "Error: No clipboard utility found (install wl-copy, xsel, or xclip)" >&2
        exit 1
    fi
fi

exit 0