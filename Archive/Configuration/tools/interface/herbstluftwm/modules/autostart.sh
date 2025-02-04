#!/bin/sh

hc() { herbstclient "$@"; }

trayPower() {
    if [ "$(pidof cbatticon)" -lt 1 ]; then
        cbatticon -i notification /sys/class/power_supply/BAT0 &
    else
        pkill cbatticon
        cbatticon -i notification /sys/class/power_supply/BAT0 &
    fi
}

volume_icon() {
    if [ "$(pidof pa-applet)" -lt 1 ]; then
        pa-applet &
    else
        pkill pa-applet
        pa-applet &
    fi
}

# AUTOSTART #
#-----------#

hc emit_hook reload
picom &
xfce4-power-manager &
# mpd --no-daemon $HOME/.config/mpd/mpd.conf &
# mpDris2 -c $HOME/.config/mpDris2/mpDris2.conf &
nm-applet &
/usr/bin/gnome-keyring-daemon --start --components=secrets
batticon
volicon

for module in $_HOME/modules; do
    case "$(basename "$module")" in
    panel) #@ Launch the panel on each monitor
        for monitor in $(hc list_monitors | cut -d: -f1); do
            "$panel" "$monitor" &
        done
        ;;
    *)
        . "$module"
        ;;
    esac
done

hc split vertical 0.6
hc remove
