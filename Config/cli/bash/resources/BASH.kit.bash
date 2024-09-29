#!/bin/bash

#==================================================
#
# PATH TOOLKIT
# /function/envman.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# --> Method
# cmd <var>

# --> Example
# skipPOSIX eval "$(starship init bash)"

# _________________________________________ POSIX<|

skipPOSIX() {
    set +o posix
    "$@"
    set -o posix
    # echo "📌 Bypassed POSIX 👟 $* 🏁"
}
