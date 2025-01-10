#! /bin/sh

#==================================================
#
# ARRAY
#
#
#==================================================
: <<'DOCUMENTATION'

https://github.com/krebs/array.git

DOCUMENTATION

# _________________________________________ LOCAL<|

DIR="${DOTS_DOWN:?}/array"
APPS="$DIR/array speedtest greap"

# echo $APPS

# for app in $APPS; do
#     case "$(basename "$app")" in
#     fasttest)
#       echo "$app found"
#       ;;
#     speedtest)
#       echo "$app found"
#       ;;
#     grep)
#       echo "$app found"
#       ;;
#     *) echo "$app not found" ;;
#     esac
# done

# cat "$app"
# alias speedtest='"$DIR"/speedtest'

unset APPS
