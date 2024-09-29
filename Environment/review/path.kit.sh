#!/bin/sh

#==================================================
#
# PATH TOOLKIT
# /function/envman.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# __________________________________________ PATH<|

# The functions below operate on PATH-like variables whose fields are separated
# with ':'.
# Note: The *name* of the PATH-style variable must be passed in as the 1st
#       argument and that variable's value is modified *directly*.

# SYNOPSIS: path_prepend varName path
# Note: Forces path into the first position, if already present.
#       Duplicates are removed too, unless they're directly adjacent.
# EXAMPLE: path_prepend PATH /usr/local/bin

# >>= Example =<< #
# _path -a /usr/local/bin       |> Append
# _path -p /usr/local/bin       |> Perpend
# _path -r /usr/local/bin       |> Remove
# _path -p /usr/local/bin -R    |> Recursive
# _path -l                      |> List

# _path_() {
#   var1=":${!1}:"
#   var1=${var1//:$2:/:}
#   var1=${var1#:}
#   var1=${var1%:}
#   printf -v "$1" '%s' "${2}${var1:+:}${var1}"
# }

# _perpend() {
#   local var1=":${!1}:"
#   var1=${var1//:$2:/:}
#   var1=${var1#:}
#   var1=${var1%:}
#   printf -v "$1" '%s' "${2}${var1:+:}${var1}"
# }

# _append() {
#   local var1=":${!1}:"
#   var1=${var1//:$2:/:}
#   var1=${var1#:}
#   var1=${var1%:}
#   printf -v "$1" '%s' "${var1}${var1:+:}${2}"
# }

# _remove() {
#   local var1=":${!1}:"
#   var1=${var1//:$2:/:}
#   var1=${var1#:}
#   var1=${var1%:}
#   printf -v "$1" '%s' "$var1"
# }

# _pathlist() {
#   clear
#   echo -n "$PATH" | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}' | tr ":" "\n"
# }

Path() {
  printf %s\\n "$PATH" |
    awk -v RS=: '!($0 in a) {
    a[$0]; 
    printf("%s%s", length(a) > 1 ? ":" : "", $0)
    }' |
    tr ":" "\n"
}

# __env__() {
#   PATH=$PATH$(
#     find "$1" \
#       -type d \
#       -printf ":%p"
#   ) && echo "$file"
# }
# _________________________________________ ALIAS<|

alias path="clear;Path"
