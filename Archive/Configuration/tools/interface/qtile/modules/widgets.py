#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# WIDGETS
# ====================================================

# ----------------------------
# ---------- Imports ---------
# ----------------------------

# === Standard === #
import subprocess

# === Third-Party === #
from libqtile import qtile, widget

# === Local === #
from modules.battery import *
from modules.control import *
from modules.declarations import *
from modules.groups import *
from modules.layouts import *

# ----------------------------
# --------- Defaults ---------
# ----------------------------


widget_defaults = dict(
    font=fontDisplay[0],
    fontsize=10,
    padding=2,
    foreground=colLight[0],
    background=colDark[0],
)

extension_defaults = widget_defaults.copy()

# ----------------------------
# ---------- Bar 1 -----------
# ----------------------------


def init_widgets_list():
    widgets_list = [
        widget.CurrentLayoutIcon(
            background=colDark[0],
            scale=0.5,
        ),
        widget.AGroupBox(
            background=colDark[0],
            foreground=colAccent[0],
            fontsize=8,
            padding=10,
            borderwidth=0,
            mouse_callbacks={
                # Left
                "Button1": lambda: qtile.cmd_spawn(Launcher[1]),
                # Middle
                "Button2": lambda: qtile.cmd_spawn(Launcher[3]),
                # Right
                "Button3": lambda: qtile.cmd_spawn(Launcher[2]),
            },
        ),
        widget.WindowName(
            foreground=colLight[0],
            background=colDark[0],
            padding=8,
        ),
        widget.WidgetBox(
            text_closed="",
            text_open="",
            font=fontIcon[1],
            fontsize=18,
            padding=0,
            close_button_location="right",
            foreground=colAccent[0],
            background=colDark[0],
            widgets=[
                widget.TextBox(text=" 🖬", padding=0, fontsize=14),
                widget.Memory(
                    padding=5,
                    # mouse_callbacks={
                    #     "Button1": lambda: qtile.cmd_spawn(sysViewer),
                    #     "Button1": lambda: qtile.cmd_spawn(sysViewer),
                    # },
                ),
                widget.ThermalSensor(metric=True, threshold=40),
            ],
        ),
        widget.GenPollText(
            func=dateNow,
            update_interval=1,
            font=fontFancy[0],
            padding=10,
            foreground=colDark[1],
            background=colAccent[0],
        ),
        widget.CheckUpdates(
            update_interval=1800,
            distro="Arch_checkupdates",
            display_format="{updates} ",
            font=fontFancy[0],
            background=colAccent[0],
            mouse_callbacks={
                # Left
                # "Button1": lambda: qtile.cmd_spawn(package_manager_update()),
                # "Button1": lambda: qtile.cmd_spawn(package_update),
                # Middle
                "Button2": lambda: qtile.cmd_spawn(sysManager[0]),
                # Right
                "Button3": lambda: qtile.cmd_spawn(appManager[0]),
            },
        ),
        widget.WidgetBox(
            text_open="",
            text_closed="",
            font=fontIcon[1],
            fontsize=18,
            padding=0,
            close_button_location="left",
            foreground=colAccent[0],
            background=colDark[0],
            foreground_alert=colAccent[1],
            widgets=[
                widget.Net(
                    interface="enp3s0",
                    font=fontDisplay[0],
                    format="{down}↓↑{up}",
                    padding=5,
                    mouse_callbacks={
                        # # Left
                        # "Button1": lambda: qtile.cmd_spawn(sysViewer[1]),
                        # # Middle
                        # "Button2": lambda: qtile.cmd_spawn(sysManager[0]),
                        # # Right
                        # "Button3": lambda: qtile.cmd_spawn(sysViewer[0]),
                    },
                ),
                widget.Volume(
                    # **widget_defaults,
                    emoji=True,
                    mouse_callbacks={
                        # Left
                        # 'Button1': lambda: qtile.cmd_spawn(sysManager[0]),
                        # Middle
                        # "Button2": lambda: qtile.cmd_spawn(sysViewer[0]),
                        # Right
                        "Button3": lambda: qtile.cmd_spawn("htop"),
                    },
                ),
                # BatteryIcon(
                #     padding=0,
                #     scale=0.7,
                #     y_poss=2,
                #     theme_path=ICONS,
                #     update_interval=5,
                # ),
                widget.Systray(
                    # background=colAccent[0],
                    padding=2,
                ),
            ],
        ),
        widget.Prompt(),
        widget.Spacer(background=colDark[0]),
        widget.GroupBox(
            background=colDark[0],
            active=colLight[0],
            inactive=colDark[2],
            block_highlight_text_color=colAccent[1],
            borderwidth=0,
            font=fontIcon[0],
            fontsize=14,
            urgent_alert_method="border",
            urgent_text=colAlert[0],
            urgent_border=colAlert[0],
            hide_unused=True,
            disable_drag=True,
        ),
        # widget.GenPollText(
        #     update_interval=1,
        #     fontsize=16,
        #     # func=lambda: subprocess.check_output(nm).decode(),
        #     # mouse_callbacks={
        #     #     "Button1": lambda: qtile.cmd_spawn(nmShow, shell=True),
        #     #     "Button3": lambda: qtile.cmd_spawn(nmUI, shell=True),
        #     # },
        # ),
    ]
    return widgets_list
