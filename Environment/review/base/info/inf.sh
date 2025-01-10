# #!/bin/sh
# # shellcheck disable=SC2034

# __lower__() {
#   printf "%s" "$@" |
#     tr '[:upper:]' '[:lower:]'
# }

# __trim__() {
#   printf "%s" "$@" |
#     tr -d '[:space:]'
# }

# __os__() {
#   printf "%s" "$(INFor --os)"
# }

# __label__ () {
#   printf "%s" "$(INFor --label)"
# }

# __type__() {
#   info="$(
#     uname --kernel-name
#   )"

#   case "$(__lower__ "$(__os__)")" in
#   *linux*) info="Linux" ;;
#   *bsd*) info="FreeBSD" ;;
#   *nt*) info="Windows" ;;
#   *windows*) info="WSL" ;;
#   *darwin*) info="Mac" ;;
#   *sunos*) info="Solaris" ;;
#   *) ;;
#   esac

#   printf "%s" "$info"
# }

# __host__() {
#   info="$(
#     uname --nodename
#   )"

#   printf "%s" "$info"
# }

# __user__() {
#   [ -n "${USER+x}" ] && info="$USER"
#   [ -n "${USERNAME+x}" ] && info="$USERNAME"
#   [ -n "${user+x}" ] && info="$user"

#   printf "%s" "$info"
# }

# __shell__() {
#   case "$(__type__)" in
#   Windows)
#     case $SHELL in
#     *bash*) info="gitSH" ;;
#     *nu*) info="nuSHell" ;;
#     *) ;;
#     esac
#     ;;
#   Linux | *WSL)
#     # active_shell="${0##/*/}"
#     case $SHELL in
#     *bash*) info="baSHell" ;;
#     *zsh*) info="zSHell" ;;
#     *dash*) info="daSHell" ;;
#     *fish*) info="fiSHell" ;;
#     *nu*) info="nuSHell" ;;
#     *) info="Undefined Linux Shell" ;;
#     esac
#     ;;
#   *) ;;
#   esac

#   printf "%s" "$info"

# }

# __wm__() {
#   info="$(
#     wmctrl -m | rg "Name" | sd "^.*:\s" ''
#   )"

#   case "$(__lower__ "$info")" in
#   *qtile*) info="qtile" ;;
#   *xmonad*) info="xmonad" ;;
#   *) ;;
#   esac

#   printf "%s" "$info"
# }

# sys_INFO="$(
#   printf "%s@%s | %s | %s | %s" \
#     "$(__user__)" \
#     "$(__host__)" \
#     "$(__trim__ "$(__os__)")" \
#     "$(__type__)" \
#     "$(__shell__)"
# )"

# sys_LABEL="$(INFor --label)"

# unset info

sys_INFO="$(
  uname -a
)"

sys_LABEL="$(os.type)"