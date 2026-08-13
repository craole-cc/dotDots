#!/bin/bash
#shellcheck enable=all
playerctl pause &
amixer set Master mute &
betterlockscreen -l
