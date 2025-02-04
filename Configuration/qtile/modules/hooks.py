#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# HOOKS
# ====================================================

# ----------------------------
# ---------- Imports ---------
# ----------------------------

# === Standard === #
import subprocess

# === Third-Party === #

from libqtile import qtile, hook

# from libqtile.command import lazy
# from libqtile.command.client import CommandClient

# === Local === #
from modules.declarations import *
from modules.groups import *


# ----------------------------
# ---------- Start -----------
# ----------------------------


# @hook.subscribe.startup_once
# def start_once():
#     subprocess.call([scr_autostart])


@hook.subscribe.startup
def start_always():
    subprocess.call("autostarter")


# ----------------------------
# --------- Previous ---------
# ----------------------------


@hook.subscribe.client_killed
def fallback(window):
    if window.group.windows != {window}:
        return

    for group in qtile.groups:
        if group.windows:
            qtile.current_screen.toggle_group(group)
            return
    qtile.current_screen.toggle_group()


# ----------------------------
# ---------- Focus -----------
# ----------------------------


# @hook.subscribe.focus_change
# def focus_change(c):
#     c = CommandClient()
#     print(c.screen.info()["index"])


@hook.subscribe.client_new
def modify_window(client):
    for group in groups:  # follow on auto-move
        match = next((m for m in group.matches if m.compare(client)), None)
        if match:
            # => there can be multiple instances of a group
            targetgroup = client.qtile.groups_map[group.name]
            targetgroup.cmd_toscreen(toggle=False)
            break
