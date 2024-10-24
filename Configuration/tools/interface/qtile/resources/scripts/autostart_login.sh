#!/bin/sh
# AUTOSTART

# === Login === #
# lxsession

# === System Utilities === #
autostarter &
sysMonitor &
# trayPower &
# trayBluetooth &
# trayVolume &
# # trayNetwork &
# trayNotification &
# Compositor &
# Mounter &
# numlockx off # Activate Numlock
# dunst &      # Notification Daemon
# nm-applet &      # Network Manager
# blueman-applet & # Bluetooth Manager
# udiskie &        # Drive auto-mounter
# flameshot &
# conky

# === Applications === #
# Editor  "$DOTS" &
# Browser &
# Communicator &
# PostOffice &
# Downloader &
# Radio &

# === Proc Monitor === #
# sleep 10 && alacritty --class btop --command btop &
#sleep 10 && sysMonitor &
