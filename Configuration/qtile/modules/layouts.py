#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# LAYOUTS
# ====================================================

# ----------------------------
# ---------- Imports ---------
# ----------------------------

# === Standard === #

# === Third-Party === #
from libqtile import layout
from libqtile.config import Match

# === Local === #
from modules.declarations import *

# ----------------------------
# ---------- Theme -----------
# ----------------------------

layout_theme = {
    "border_width": 3,
    "margin": 4,
    "border_focus": colAccent[0],
    "border_normal": colDark[0],
}

# ----------------------------
# --------- Standard ---------
# ----------------------------

layouts = [
    # layout.Bsp(
    #     **layout_theme
    # ),
    # layout.Columns(
    #     **layout_theme
    # ),
    # layout.Floating(
    #     *layout_theme
    # ),
    # layout.Matrix(
    #     **layout_theme
    # ),
    layout.MonadTall(**layout_theme),
    layout.MonadWide(**layout_theme),
    layout.Max(**layout_theme),
    # layout.Stack(
    #     num_stacks=2
    # ),
    # layout.Tile(
    #     shift_windows=True,
    #     **layout_theme
    # ),
    # layout.TreeTab(
    #     font='Ubuntu',
    #     fontsize=10,
    #     sections=['FIRST', 'SECOND'],
    #     section_fontsize=11,
    #     bg_color='141414',
    #     active_bg='90C435',
    #     active_fg='000000',
    #     inactive_bg='384323',
    #     inactive_fg='a0a0a0',
    #     padding_y=5,
    #     section_top=10,
    #     panel_width=320
    # ),
    # layout.RatioTile(
    #     **layout_theme
    # ),
    # layout.Verticaltile(
    #     **layout_theme
    # ),
    # layout.Zoomy(
    #     **layout_theme
    # ),
]


# ----------------------------
# --------- Floating ---------
# ----------------------------


floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class=flClass),
        # Match(title=flName),
    ]
)
