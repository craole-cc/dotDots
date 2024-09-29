#! /bin/sh

#==================================================
#
# PICOM
# CLI/bin/environment/app/picom.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# _________________________________________ LOCAL<|

DIR="${XDG_CONFIG_HOME:?}/picom"
PICOM_CONFIG="${DIR}/picom.conf"
PID=$(pgrep picom)

# ______________________________________ EXTERNAL<|

# --> Edit Config
cfPicom() {
    $1 "$PICOM_CONFIG"
}

# --> Deactivate
kPicom() { pkill picom; }

# --> Activate
rPicom() {
    PID=$(pgrep picom)
    [ -z "$PID" ] &&
        picom \
            --daemon \
            --experimental-backends \
            --config "$PICOM_CONFIG"
}

# --> Toggle
tPicom() {
    PID=$(pgrep picom)
    if [ "$PID" ]; then
        kPicom
    else
        rPicom
    fi
}

# --> Help and ERROR
hPicom() {
    cat <<EOF
   foobar $Options
  $*
          Usage: foobar <[options]>
          Options:
                  -b   --bar            Set bar to yes    ($foo)
                  -f   --foo            Set foo to yes    ($bart)
                  -h   --help           Show this message
                  -A   --arguments=...  Set arguments to yes ($arguments) AND get ARGUMENT ($ARG)
                  -B   --barfoo         Set barfoo to yes ($barfoo)
                  -F   --foobar         Set foobar to yes ($foobar)
EOF
}

# ________________________________________ EXPORT<|

Picom() {
    while getopts ':rkh-E:TF' OPTION; do
        case "$OPTION" in
        h) hPicom ;;
        r) rPicom ;;
        k)Pi kPicom ;;
        E)
            sARG="$OPTARG"
            ;;
        T) sbarfoo=yes ;;
        F) sfoobar=yes ;;
        -)
            [ $OPTIND -ge 1 ] && optind=$(($OPTIND - 1)) || optind=$OPTIND
            # -) [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1) || optind=$OPTIND
            eval OPTION="\$$optind"
            OPTARG=$(echo $OPTION | cut -d'=' -f2)
            OPTION=$(echo $OPTION | cut -d'=' -f1)
            case $OPTION in
            --run) _rPicom ;;
            --kill) kPicom;;
            --help) hPicom ;;
            --toggle) tPicom ;;
            --edit)
                larguments=yes
                lARG="$OPTARG"
                ;;
            *) hPicom " Long: >>>>>>>> invalid options (long) " ;;
            esac
            OPTIND=1
            shift
            ;;
        ?) hPicom "Short: >>>>>>>> invalid options (short) " ;;
        esac
    done
}

# while getopts rkthc: arg; do
#     case $arg in
#     h)
#         usage
#         exit 2
#         ;;
#     t) # Toggle
#         tPicom ;;
#     k) # Kill
#         kPicom ;;
#     c) # config
#         kPicom ;;
#     r | *) # Activate
#         rPicom ;;
#     esac
# done

# __________________________________________ EXEC<|
