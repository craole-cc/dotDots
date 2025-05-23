#!/bin/sh

#==================================================
#
# XINITRC
# Tools/X11/xinitrc
#
#==================================================

# ________________________________________ SYSTEM<|

#> Xinitrc
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

#> Xresources
# [ -f "$RC_xresources_sys" ] && xrdb -merge "$RC_xresources_sys"
# [ -f "$RC_xresources" ] && xrdb -merge "$RC_xresources"

#> Xmodmap
# [ -f "$RC_xmodmad_sys" ] && xmodmap "$RC_xmodmap_sys"
# [ -f "$RC_xmodmad" ] && xmodmap "$RC_xmodmap"

#> Fonts
# xset +fp /usr/share/fonts/TTF/
# xset fp rehash

# _______________________________________ UTILITY<|

# numlockx on # Activate Numlock
# udiskie &     # Drive auto-mounter
# udiskie --automount --tray --notify & # Drive auto-mounter
# nm-applet &  # Network Manager
# nm-tray & # Network Manager
# volumeicon & # Audio Manager
# flameshot &  # Screenshot Utility

# _______________________________________ DISPLAY<|

# dunst &     # --> Notifications
picom &     # --> Compositor
wallpaint & # --> Wallpaper

# ________________________________ AUTHENTICATION<|

eval "$(
  gnome-keyring-daemon \
    --daemonize \
    --components=pkcs11,secrets,ssh
)"
export SSH_AUTH_SOCK

# __________________________________________ APPS<|

# VScode "$codeDOTS" & # --> Dotfiles Workspace (VScode)
# Firefox &
# Top &

# ____________________________________________ WM<|

# qtile start --config "$RC_QTILE" --log-level ERROR
