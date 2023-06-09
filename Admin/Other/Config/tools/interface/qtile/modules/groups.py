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
from libqtile.config import DropDown, Group, Key, Match, ScratchPad
from libqtile.lazy import lazy

# === Local === #
from modules.control import *
from modules.workspaces import *

# ----------------------------
# --------- GROUPS -----------
# ----------------------------

groups = []

for workspace in workspaces:
    gKey = workspace["key"]
    gName = workspace["name"]
    gLabel = workspace["label"]
    gLayout = workspace["layout"].lower()
    gClass = Match(wm_class=workspace["wm_class"])
    gTitle = Match(title=workspace["wm_name"])

    # === Groups === #
    groups.append(
        Group(
            name=gName,
            label=gLabel,
            layout=gLayout,
            matches=gClass or gTitle,
        ),
    )

    # === KEYS === #
    keys.extend(
        [
            Key(
                sup,
                gKey,
                lazy.group[gName].toscreen(),
                desc="Navigate workspaces {1,2,3,4,5,6,7,8,9,0}",
            ),
            Key(
                supS,
                gKey,
                lazy.window.togroup(gName),
                lazy.group[gName].toscreen(),
                desc="Move active window to selected workspace and navigate there",
            ),
            Key(
                supC,
                gKey,
                lazy.window.togroup(gName),
                desc="Move active window to selected workspace",
            ),
        ]
    )

# ----------------------------
# -------- FUNCTIONS ---------
# ----------------------------


@lazy.function
def window_to_prev_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i - 1].name)


@lazy.function
def window_to_next_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i + 1].name)


dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
auto_fullscreen = True
auto_minimize = True
# focus_on_window_activation = "smart"
focus_on_window_activation = "focus"