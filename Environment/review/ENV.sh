#!/bin/sh

#==================================================
#
# ENVIRONMENT MANAGER
# /function/envman.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

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

# ________________________________________ SOURCE<|

__dir__() {
  fd . \
    --full-path "$1" \
    --hidden \
    --exclude archive \
    --exclude temp \
    --exclude test \
    --exclude debug
}

__pendP__() {
  PATH="$1${PATH:+:${PATH}}"
}

__Ppend__() {
  PATH="${PATH:+${PATH}:}$1"
}

__Plist__() {
  printf %s\\n "$PATH" |
    awk -v RS=: '!($0 in a) {
    a[$0]; 
    printf("%s%s", length(a) > 1 ? ":" : "", $0)
    }' |
    tr ":" "\n"
}

__perm__() {
  chmod 755 "$1"
}

__src__() {
  # chmod 755 "$1" &&
  . "$1"
}

__env__() {
  for SOURCE in $(
    __dir__ "$1"
  ); do
    if [ -d "$SOURCE" ]; then
      __pendP__ "$SOURCE"
    else
      __src__ "$SOURCE"
    fi
    # echo "$SOURCE" DIR ||
    # echo "$SOURCE" FILE
  done
}

# __env__ "$shFUN"
# __env__ "$shENV"
# __env__ "$shDBG"
# [ -d /home/craole/Dotfiles/CLI/environment/packages/starship.sh ] && echo "dir" || echo "file"

# __src__() {
#   for SOURCE in $(
#     fd . \
#       --full-path "$1" \
#       --hidden \
#       --exclude archive \
#       --exclude tmp
#   ); do

#     # Set Read/Write/Execute Permissions
#     __perm__ "$SOURCE"

#     # Add Directories to PATH
#     if [ -d "$SOURCE" ]; then
#       __env__ "$SOURCE" &&
#         echo "$SOURCE" added to path

#     else

#       # Source Files
#       . "$SOURCE" &&
#         echo "$SOURCE" sourced
#     fi
#   done
# }

# --type f \
# chmod u=rw,go=r,a+X "$FILE" &&
# chmod u=rwx,g=rx,o=r "$FILE" &&
# chmod +x "$FILE" &&

# Path() {
#   printf %s\\n "$PATH" |
#     awk -v RS=: '!($0 in a) {
#     a[$0];
#     printf("%s%s", length(a) > 1 ? ":" : "", $0)
#     }' |
#     tr ":" "\n"
# }

# __env__() {
#   PATH=$PATH$(
#     find "$1" \
#       -type d \
#       -printf ":%p"
#   ) && echo "$1"
# }

# __env__() {
#   PATH=$PATH$(
#     find "$1" \
#       -type d \
#       -printf ":%p"
#   ) && echo "$file"
# }

# _path_() {
#   for DIR in $(
#     fd . \
#       --full-path "$1" \
#       --type d \
#       --hidden \
#       --exclude archive
#   ); do
#     PATH=$PATH$("$DIR"
#     )
#   done
# }
