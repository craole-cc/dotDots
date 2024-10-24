#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# GROUPS
# ====================================================


# ----------------------------
# ---------- Imports ---------
# ----------------------------

# === Standard === #

# === Third-Party === #
from libqtile.config import DropDown, Key, ScratchPad
from libqtile.lazy import lazy

# === Local === #
from modules.groups import *
from modules.control import *

# ----------------------------
# ------- SCRATCHPADS --------
# ----------------------------
# https://docs.qtile.org/en/latest/manual/config/groups.html

groups.append(
    ScratchPad(
        "ScratchPad",
        [
            DropDown(
                "TerminalEmulator",
                # "Kitty",  #| BIN::Kitty
                "kitty --config /home/craole/DOTS/Config/apps/kitty/kitty.conf",
                # "kitty --config /home/craole/DOTS/Config/tools/interface/qtile/resources/config/kitty.conf",
                # "kitty --config" + str(KITTY_CONF),
                height=0.5,
                width=1,
                x=0,
                y=.5,
                opacity=1,
                on_focus_lost_hide=False,
            ),
            DropDown(
                "AppLauncher",
                "Launcher",
                # height=0.45,
                # opacity=1,
                on_focus_lost_hide=False,
            ),
            DropDown(
                "thunderbird",
                "thunderbird",
                height=0.8,
                width=0.8,
                x=0.1,
                y=0.1,
                on_focus_lost_hide=True,
                opacity=0.95,
                warp_pointer=True,
            ),
        ],
    ),
)

# === KEYS === #
keys.extend(
    [
        Key(
            sup,
            "Grave",
            lazy.group["ScratchPad"].dropdown_toggle("TerminalEmulator"),
            desc="Dropdown Terminal",
        ),
        # Key(
        #     sup,
        #     "Space",
        #     lazy.group["ScratchPad"].dropdown_toggle("AppLauncher"),
        #     desc="Application Launcher",
        # ),
    ]
)
