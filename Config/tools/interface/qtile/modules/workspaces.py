#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# WORKSPACES
# ====================================================

# ----------------------------
# -------- WORKSPACES --------
# ----------------------------


workspaces = [
    # {
    #     "key": "grave",
    #     # "label": " ",
    #     "label": " ",
    #     "name": "TERM",
    #     "layout": "monadtall",
    #     "wm_class": [
    #         "alacritty",
    #         # "kitty",
    #         "st",
    #     ],
    #     "wm_name": [],
    # },
    {
        "key": "1",
        "label": " ₁",
        "name": "CODE",
        "layout": "max",
        "wm_class": [
            "code",
            "code-oss",
            "jetbrains-idea-ce",
        ],
        "wm_name": [],
    },
    {
        "key": "2",
        "label": " ₂",
        "name": "WWW",
        "layout": "monadwide",
        "wm_class": [
            "firefox",
            "brave-browser",
            "Brave-browser-nightly",
            "chromium",
            "google-chrome",
            "qutebrowser",
        ],
        "wm_name": [],
    },
    {
        "key": "3",
        "label": " ₃",
        "name": "TOOL",
        "layout": "monadtall",
        "wm_class": [
            "fontmatrix",
            "Font-manager",
            "pcmanfm-qt",
            "Double Commander",
            "Thunar" "thunar" "Pamac-manager",
            "stacer",
            "notion-app-enhanced",
        ],
        "wm_name": [
            "*Double Commander*",
            "*thunar*",
        ],
    },
    {
        "key": "4",
        "label": " ₄",
        "name": "COMMS",
        "layout": "monadtall",
        "wm_class": [
            "thunderbird",
            "Daily",
            "evolution",
            "geary",
            "mail",
            "skype",
            "zoom",
            "Mail",
            "Thunderbird",
        ],
        "wm_name": [],
    },
    {
        "key": "5",
        "label": "行  ₅",
        "name": "PICS",
        "layout": "max",
        "wm_class": [
            # 'sxiv',
            "feh",
            "nomacs",
            "instagram-nativefier-51e18f",
            "whatsapp-nativefier-d40211",
        ],
        "wm_name": [],
    },
    {
        "key": "6",
        "label": "露 ₆",
        "name": "MUSIC",
        "layout": "monadtall",
        "wm_class": [
            "yarock",
            "deadbeef",
            "spotify",
            "MellowPlayer",
            "shortwave",
            "de.haeckerfelix.Shortwave",
        ],
        "wm_name": ["curseradio"],
    },
    {
        "key": "7",
        "label": "磊 ₇",
        "name": "FILM",
        "layout": "max",
        "wm_class": [
            # 'mpv',
            "freetube",
            "smtube",
            "vlc",
            "Gtk-pipe-viewer",
        ],
        "wm_name": [],
    },
    {
        "key": "8",
        "label": " ",
        "name": "FUN",
        "layout": "max",
        "wm_class": [
            "qBittorrent",
        ],
        "wm_name": [],
    },
    {
        "key": "9",
        "label": "勇 ",
        "name": "PRIV",
        "layout": "monadtall",
        "wm_class": [
            "emacs",
            "vivaldi-stable",
        ],
        "wm_name": ["*vivaldi-*"],
    },
    {
        "key": "0",
        "label": "ﱨ",
        "name": "INFO",
        "layout": "max",
        "wm_class": [
            "btop",
            "bpytop",
            "top",
            "htop",
            "btm",
            "dust",
            "gotop",
            "bottom",
            "Top",
            "stacer",
            "sys_monitor",
            "System Monitor",
            "Lockscreen Wallpaper Update",
        ],
        "wm_name": [
            "btop",
        ],
    },
]
