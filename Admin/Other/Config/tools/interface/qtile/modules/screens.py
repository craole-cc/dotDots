#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# SCREENS
# ====================================================

# ----------------------------
# ---------- Imports ---------
# ----------------------------

# === Standard === #

# === Third-Party === #
from libqtile import bar
from libqtile.config import Screen

# === Local === #
from modules.groups import *
from modules.widgets import *
from modules.declarations import *

# ----------------------------
# --------- Widgets ----------
# ----------------------------


def init_widgets_screen1():
    widgets_screen1 = init_widgets_list()
    return widgets_screen1


def init_widgets_screen2():
    widgets_screen2 = init_widgets_list()
    return widgets_screen2


widgets_screen1 = init_widgets_screen1()
widgets_screen2 = init_widgets_screen2()


def init_screens():
    return [
        Screen(
            top=bar.Bar(
                widgets=init_widgets_screen1(),
                size=20,
                opacity=0.90,
            ),
            wallpaper=WALLPAPER,
            wallpaper_mode="fill",
        ),
        Screen(
            bottom=bar.Bar(
                widgets=init_widgets_screen2(),
                size=20,
                opacity=0.90,
            ),
            wallpaper=WALLPAPER,
            wallpaper_mode="fill",
        ),
    ]


screens = init_screens()
reconfigure_screens = True
