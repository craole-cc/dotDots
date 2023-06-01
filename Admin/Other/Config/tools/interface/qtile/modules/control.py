#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# CONTROL
# ====================================================


# ----------------------------
# ---------- Imports ---------
# ----------------------------l

# === Standard === #
from typing import List  # noqa: F401

# === Third-Party === #
from libqtile.command import lazy
from libqtile.config import Click, Drag, Key, KeyChord
from libqtile.utils import guess_terminal

# === Local === #
from modules.declarations import *

# ----------------------------
# --------- Hotkeys ----------
# ----------------------------

keys = [
    # === Qtile Control ===#
    Key(supC, "q", lazy.shutdown(), "Logout"),
    Key(supC, "r", lazy.restart(), "Restart Qtile"),
    Key(supS, "r", lazy.reload_config(), "Reload the Qtile config"),
    Key(sup, "Return", lazy.spawn(term_emulator()), "Default Terminal"),
    Key(sup, "r", lazy.spawncmd(), "Default Launcher"),
    Key(supS, "w", lazy.screen.set_wallpaper(DEFAULT_WALLPAPER, mode="fill")),
    # === Groups/Workspaces ===#
    Key(supA, "Tab", lazy.screen.toggle_group(), "Move to previous group"),
    Key(sup, "Tab", lazy.screen.next_group(), "Cycle forward through groups"),
    Key(supS, "Tab", lazy.screen.prev_group(), "Cycle backward through groups"),
    Key(supA, "Tab", lazy.next_layout(), desc="Toggle previous group"),
    # === Window/Layout ===#
    # Key(sup, "w", lazy.window.kill(),"Close active window (Default)"),
    Key(supS, "q", lazy.spawn(appKill[0]), "Force close sleceted window"),
    Key(sup, "q", lazy.window.kill(), "Close active window"),
    Key(alt, "F4", lazy.window.kill(), "Close active window"),
    Key(supA, "Return", lazy.window.toggle_fullscreen(), "Toggle fullscreen mode"),
    Key(altS, "Return", lazy.window.toggle_floating(), "Toggle floating mode"),
    Key(
        alt,
        "Tab",
        lazy.layout.down(),
        "Move focus down in current stack pane",
    ),
    Key(
        altS,
        "Tab",
        lazy.layout.up(),
        "Move focus up in current stack pane",
    ),
    Key(supC, "Tab", lazy.layout.maximize(), "Cycle backward through layouts"),
    Key(supC, "Next", lazy.next_layout(), "Cycle forward through layouts"),
    Key(supC, "Prior", lazy.prev_layout(), "Cycle backward through layouts"),
    Key(supC, "Home", lazy.layout.reset(), ""),
    Key(
        supC,
        "space",
        lazy.layout.rotate(),
        lazy.layout.flip(),
        "Switch which side main pane occupies",
    ),
    Key(
        supC,
        qUp,
        lazy.layout.grow_main(),
        lazy.layout.increase_ratio(),
        lazy.layout.increase_nmaster(),
        "Increase space occupied by master window",
    ),
    Key(
        supC,
        qDown,
        lazy.layout.shrink_main(),
        lazy.layout.decrease_ratio(),
        lazy.layout.decrease_nmaster(),
        "Decrease space occupied by master window",
    ),
    Key(
        supC,
        qRight,
        lazy.layout.shuffle_down(),
        "Move windows down in current stack",
    ),
    Key(
        supC,
        qLeft,
        lazy.layout.shuffle_up(),
        "Move windows up in current stack",
    ),
    # Key(
    #     supA,
    #     "space",
    #     lazy.layout.toggle_split(),
    #     "Toggle between split and unsplit sides of stack",
    # ),
    # Key(
    #     supC,
    #     "KP_Subtract",
    #     lazy.layout.section_down(),
    #     "Move down a section in treetab",
    # ),
    # Key(
    #     altC,
    #     "KP_Add",
    #     lazy.layout.section_up(),
    #     "Move up a section in treetab",
    # ),
    # === Session ===#
    # Key([], "XF86RFKill", lazy.spawn()), #@ This breaks the config
    # === Backlight ===#
    Key([], "XF86MonBrightnessDown", lazy.spawn(backlight_ctl[0])),
    Key([], "XF86MonBrightnessUp", lazy.spawn(backlight_ctl[1])),
    # === Audio ===#
    Key([], "XF86AudioMute", lazy.spawn(audio_ctl[0])),
    Key([], "XF86AudioLowerVolume", lazy.spawn(audio_ctl[1])),
    Key([], "XF86AudioRaiseVolume", lazy.spawn(audio_ctl[2])),
    # === Media ===#
    # Key([], "XF86AudioPrev", lazy.spawn()),
    # Key([], "XF86AudioPlay", lazy.spawn(),
    # Key([], "XF86AudioStop", lazy.spawn(),
    # Key([], "XF86AudioNext", lazy.spawn()),
    # === Screenshot ===#
    # Key([], "Print", lazy.spawn(),
    # PrtSc – Save a screenshot of the entire screen to the “Pictures” directory.
    # Shift + PrtSc – Save a screenshot of a specific region to Pictures.
    # Alt + PrtSc  – Save a screenshot of the current window to Pictures.
    # Ctrl + PrtSc – Copy the screenshot of the entire screen to the clipboard.
    # Shift + Ctrl + PrtSc – Copy the screenshot of a specific region to the clipboard.
    # Ctrl + Alt + PrtSc – Copy the screenshot of the current window to the clipboard.
    # === Applications ===#
    Key(sup, "Space", lazy.spawn(Launcher[0]), desc="Default Launcher"),
    Key(
        supS,
        "l",
        # lazy.spawn(lockuper),
        lazy.spawn(lockscreen_update()),
        desc="Update Lockscreen Wallpaper",
    ),
    # Key(sup, "l", lazy.spawn(lockscreen()), desc="Lockscreen"),
    Key(sup, "u", lazy.spawn(package_manager_update()), desc="Package Update"),
    Key(ctlS, "q", lazy.spawn(system_monitor)),
    # Key(ctlS, "Escape", lazy.spawn("kitty -e bpytop")),
    # @ Defaults from DOTS_BIN
    # Key(supA, "d", lazy.spawn("VScode --dots")),
    # Key(supA, "r", lazy.spawn("VScode --rust")),
    # Key(sup, "c", lazy.spawn("Editor")),
    # Key(sup, "b", lazy.spawn("Browser")),
    # Key(supS, "b", lazy.spawn("Browser")),
    # Key(sup, "e", lazy.spawn("FileManager")),
    Key(ctl, "Escape", lazy.spawn("sysMonitor")),
    Key(supA, "Period", lazy.spawn("wAllter")),
    Key(supA, "Comma", lazy.spawn("wAllter --previous")),
    Key(sup, "l", lazy.spawn("Lockscreen")),
    Key(supA, "l", lazy.spawn("Lockscreen --update")),
    Key(sup, "v", lazy.spawn("VNC")),
    Key(sup, "n", lazy.spawn("Note")),
    Key(supA, "u", lazy.spawn("sysUpdate")),
    Key(supS, "u", lazy.spawn("sysUpdate --full")),
    KeyChord(
        sup,
        "p",
        [
            Key([], "r", lazy.spawn("shortwave")),
            Key([], "t", lazy.spawn("Tube")),
        ],
        name="Media Player",
    ),
    KeyChord(
        sup,
        "c",
        [
            Key([], "v", lazy.spawn("VScode")),
            Key([], "d", lazy.spawn("VScode --dots")),
            Key([], "r", lazy.spawn("VScode --rust")),
            Key([], "n", lazy.spawn("VScode --nix")),
        ],
        name="Visual Studio Code",
    ),
    KeyChord(
        sup,
        "e",
        [
            Key([], "f", lazy.spawn("launch doublecmd")),
            Key([], "g", lazy.spawn("Editor --type gui")),
            Key([], "t", lazy.spawn("Editor --type tty")),
        ],
        name="Editor",
    ),
    KeyChord(
        sup,
        "b",
        [
            Key([], "f", lazy.spawn("Firefox")),
            Key([], "b", lazy.spawn("Brave")),
            Key([], "p", lazy.spawn("polypane")),
        ],
        name="Browser",
    ),
]

mouse = [
    Drag(
        sup,
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
        # desc="Hold the mod key to drag windows with the left mouse button",
    ),
    Click(
        sup,
        "Button2",
        lazy.window.bring_to_front(),
        # desc="Float window with the middle mouse button",
    ),
    Drag(
        sup,
        "Button3",
        lazy.window.set_size_floating(),
        start=lazy.window.get_size(),
        # desc="Hold the mod key to resize the windows with the right button",
    ),
]
