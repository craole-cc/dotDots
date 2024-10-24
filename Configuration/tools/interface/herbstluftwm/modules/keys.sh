#!/bin/sh

mod=mod1 # Use alt as the main modifier
#mod=mod4   # Use the super key as the main modifier

# REMOVE ALL EXISTING KEYBINDINGS #
#---------------------------------#
hc keyunbind --all

# System controls #
#-----------------#
hc keybind "${mod}"-Shift-c spawn alacritty -t logout -e herbst-logout.sh
hc keybind "${mod}"-Control-r reload
hc keybind "${mod}"-Shift-q close
hc keybind "${mod}"-Shift-Return spawn "${TERMINAL:-alacritty}" #

# multimedia #
#------------#
hc keybind XF86MonBrightnessUp spawn lux -a 10%
hc keybind XF86MonBrightnessDown spawn lux -s 10%
hc keybind XF86AudioRaiseVolume spawn pactl set-sink-volume 0 +5%
hc keybind XF86AudioLowerVolume spawn pactl set-sink-volume 0 -5%
hc keybind XF86AudioMute spawn pactl set-sink-mute @DEFAULT_SINK@ toggle
hc keybind XF86AudioPlay spawn playerctl play-pause
hc keybind XF86AudioNext spawn playerctl next
hc keybind XF86AudioPrev spawn playerctl previous
hc keybind "${mod}"-Control-s spawn playerctl stop

# programs #
# #--------#
hc keybind "${mod}"-w spawn bgd
hc keybind "${mod}"-Control-y spawn ~/.local/scripts/ytsubs.sh
hc keybind "${mod}"-Shift-t spawn scratch Todo
hc keybind "${mod}"-Shift-w spawn alacritty -t windows -e windows.sh
hc keybind "${mod}"-a spawn alacritty
hc keybind "${mod}"-c spawn conktoggle.sh
# run launchers #
#---------------#
#hc keybind "${mod}"-Control-f spawn dmenu_run -p Launch: -fn Hermit:size=10 -l 10 -g 7 -nb '#222222' -sb '#007687' -sf '#222222' -nf '#b8b8b8'
hc keybind "${mod}"-Shift-r spawn rofi -show drun
hc keybind "${mod}"-Control-e spawn rofi -show emoji
hc keybind "${mod}"-Shift-v spawn alacritty -t vmach.sh -e vmach.sh
hc keybind "${mod}"-Shift-i spawn alacritty -t vsp2 -e vsp2
hc keybind "${mod}"-Shift-d spawn alacritty -t launch.sh -e launch.sh
hc keybind "${mod}"-Shift-e spawn alacritty -t configs -e edit_configs.sh
hc keybind "${mod}"-Control-t spawn alacritty -t themesel.sh -e themesel.sh

# browsers #
#----------#
hc keybind "${mod}"-Shift-b spawn brave-browser-stable
hc keybind "${mod}"-Shift-a spawn firefox
hc keybind "${mod}"-Shift-n spawn nyxt

hc keybind Print spawn flameshot gui

# scratchpads #
#-------------#
hc keybind "${mod}"-Return spawn scratch scratchpad
hc keybind "${mod}"-Control-f spawn scratch FM
hc keybind "${mod}"-q spawn scratch2 qutebrowser
hc keybind "${mod}"-Control-Return spawn scratchpad
hc keybind "${mod}"-m spawn scratch Mail
hc keybind "${mod}"-t spawn scratch Music
hc keybind "${mod}"-Control-c spawn scratch2 Calc
hc keybind "${mod}"-y spawn scpad

# focusing client #
#-----------------#s
hc keybind "${mod}"-Left focus left
hc keybind "${mod}"-Down focus down
hc keybind "${mod}"-Up focus up
hc keybind "${mod}"-Right focus right

# moving clients in tiling and floating mode #
hc keybind "${mod}"-Shift-Down shift down
hc keybind "${mod}"-Shift-Up shift up
hc keybind "${mod}"-Shift-Right shift right
hc keybind "${mod}"-Shift-Left shift left

# splitting frames #
#------------------#
hc keybind "${mod}"-u split bottom 0.6
hc keybind "${mod}"-o split right 0.6

# let the current frame explode into subframes #
#----------------------------------------------#
hc keybind "${mod}"-Control-space split explode

# resizing frames and floating clients #
#--------------------------------------#
resizestep=0.02
hc keybind "${mod}"-Control-Left resize left +"${resizestep}"
hc keybind "${mod}"-Control-Down resize down +"${resizestep}"
hc keybind "${mod}"-Control-Up resize up +"${resizestep}"
hc keybind "${mod}"-Control-Right resize right +"${resizestep}"

# tags #
#------#
tag_names=({1..9})
tag_keys=({1..9} 0)

hc rename default "${tag_names[0]}" || true
for i in "${!tag_names[@]}"; do
    hc add "${tag_names[$i]}"
    hc set_layout horizontal
    hc set default_frame_layout 1
    key="${tag_keys[$i]}"
    if ! [ -z "$key" ]; then
        hc keybind ""${mod}"-$key" use_index "$i"
        hc keybind ""${mod}"-Shift-$key" move_index "$i"
    fi
done

# layouting #
#-----------#
hc keybind "${mod}"-Shift-s spawn new-layout.sh
hc keybind "${mod}"-Shift-l spawn ./.local/scripts/load-layout.sh
hc keybind "${mod}"-r remove
hc keybind "${mod}"-f fullscreen toggle
hc keybind "${mod}"-Shift-f set_attr clients.focus.floating toggle
hc keybind "${mod}"-p pseudotile toggle
# The following cycles through the available layouts within a frame, but skips
# layouts, if the layout change wouldn't affect the actual window positions.
# I.e. if there are two windows within a frame, the grid layout is skipped.
hc keybind "${mod}"-space \
    or , and . compare tags.focus.curframe_wcount = 2 \
    . cycle_layout +1 vertical horizontal max vertical grid \
    , cycle_layout +1

# focus #
#-------#
hc keybind "${mod}"-BackSpace cycle_monitor
hc keybind "${mod}"-Tab cycle_all +1
hc keybind "${mod}"-Shift-Tab cycle_all -1
hc keybind "${mod}"-i jumpto urgent

# MOUSE #
#-------#
hc mouseunbind --all
hc mousebind "${mod}"-Button1 move
hc mousebind "${mod}"-Button2 zoom
hc mousebind "${mod}"-Button3 resize
