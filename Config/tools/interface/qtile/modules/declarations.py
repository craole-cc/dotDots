#!/usr/bin/env python3
# coding=utf-8

# ====================================================
# DEFINITIONS
# ====================================================

# ----------------------------
# ---------- Imports ---------
# ----------------------------

# >>= Standard =<< #
from datetime import datetime as dt
from inspect import currentframe, getframeinfo
from pathlib import Path

# >>= Third-Party =<< #
from libqtile.utils import guess_terminal

# >>= Local =<< #
from classes.tty_cmd import TTY_cmd
from functions.wehave import wehave, wehave_location
from functions.find_parent import *
from functions.wallpaper import *

# ----------------------------
# ----------- Paths ----------
# ----------------------------
# >>= Qtile =<< #
DECLARATIONS = getframeinfo(currentframe()).filename
QTILE_HOME = Path(DECLARATIONS).resolve().parent.parent
# QTILE_HOME = find_parent("qtile")
TESTS = QTILE_HOME / "tests"
MODULES = QTILE_HOME / "modules"
RESOURCES = QTILE_HOME / "resources"
SCRIPTS = RESOURCES / "scripts"
THEMES = RESOURCES / "themes"
ICONS = RESOURCES / "icons"
ROFI = THEMES / "rofi"
CTRL = MODULES / "control.py"
DEFAULT_WALLPAPER = RESOURCES / "pictures" / "wallpaper.jpg"
KITTY_CONF = RESOURCES / "config" / "kitty.conf"
# print(ROFI)

# >>= Global =<< #
HOME = Path.home()

# Dotfiles
DOTS = HOME / "DOTS"
DOTS_CFG = DOTS / ".dotsrc"
DOT_BIN = DOTS / "Bin"
DOT_CONF = DOTS / "Config"
DOT_DOC = DOTS / "Documentation"
DOT_ENV = DOTS / "Environment"
DOT_RES = DOTS / "Resources"
DOT_SCR = DOTS / "Scripts"
DOT_TEST = DOTS / "Test"

PICTURES = HOME / "Pictures"
SCREENSHOTS = PICTURES / "Screenshots"
WALLPAPERS = PICTURES / "wallpapers"
DMENU_BIN = DOT_BIN / "utility/dmenu"

# >>= Battery =<< #
POWER_SUPPLY = Path("/sys/class/power_supply")
BATTERY = sorted(POWER_SUPPLY.rglob("BAT*"))

# Establish Paths
paths_to_establish = [SCREENSHOTS, WALLPAPERS]


# for path in paths_to_establish:
#     if not Path.exists(path):
#         path.mkdir(parents=True, exist_ok=True)

# for child in modules.iterdir():
#     print(f'{child})

WALLPAPER = get_random_image(WALLPAPERS, default=DEFAULT_WALLPAPER)

# ----------------------------
# --------- Scripts ----------
# ----------------------------

# >>= Qtile =<< #
# | Make scripts executable
# SCRIPTS.chmod(755)
scr_apps = DOTS / "scripts" / "qtile.robot"
scr_login = SCRIPTS / "autostart_login.sh"
scr_autostart = SCRIPTS / "autostart.sh"
scr_reload = SCRIPTS / "autostart_reload.sh"
scr_compositor = SCRIPTS / "picom.sh"
scr_wallpaper = SCRIPTS / "pywal.sh"
scr_resolution = SCRIPTS / "resolution.sh"
# print(scr_reload)
TTY = TTY_cmd()


# >>= Global =<< #Paths
# nm = DOT_BIN / "network.sh"
# nmShow = DOT_BIN / "network.sh ShowInfo"

# ----------------------------
# ------ Modifier Keys -------
# ----------------------------

alt = ["mod1"]
sht = ["shift"]
ctl = ["control"]
sup = ["mod4"]
supA = ["mod4", "mod1"]
supS = ["mod4", "shift"]
supC = ["mod4", "control"]
ctlS = ["control", "shift"]
altS = ["mod1", "shift"]
altC = ["mod1", "control"]
altSC = ["mod1", "shift", "control"]
supSC = ["mod4", "shift", "control"]
qUp = "k"
qDown = "j"
qLeft = "h"
qRight = "l"

# ----------------------------
# --------- Colors -----------
# ----------------------------

colLight = [
    "#ECEDEC",
    "#CECECE",
    "#6d6e6f",
    "#7DD575",
]
colDark = [
    "#272727",
    "#0e0c0b",
    "#36383E",
    "#1C1B22",
    "#3d3f4b",
    "#110015E0",
]
colAccent = [
    "#009c37",
    "#fed200",
    "#018a2d",
    "#a65a42",
    "#8800AA",
]
colAlert = [
    "#FF0000",
    "#d51c2c",
    "#fcde03",
    "#FF6F00",
]

theme_green = [
    colDark[0],
    colLight[0],
    colAccent[0],
    colAlert[0],
]
# ----------------------------
# ---------- Fonts -----------
# ----------------------------
# fonts = [
#     {
#         "Icon": [
#             "FiraCode Nerd Font",
#             "Hack Nerd Font",
#             "CaskaydiaCove Nerd Font",
#             "HeavyData Nerd Font",
#         ]
#     },
#     {
#         "Display": [
#             "Comfortaa Bold",
#             "Rec Mono Casual",
#             "Cascadia Code Bold",
#         ],
#     },
#     {
#         "Fancy": [
#             "OpenDyslexic Nerd Font",
#             "VictorMono Nerd Font Bold Italic",
#         ]
#     },
# ]

fontIcon = [
    # 'Operator Mono Lig'
    "Hack Nerd Font",
    "HeavyData Nerd Font",
]

fontDisplay = [
    "Comfortaa Bold",
    "Rec Mono Casual",
    "Cascadia Code Bold",
]

fontFancy = [
    "OpenDyslexic Nerd Font",
    "VictorMono Nerd Font Bold Italic",
]

# ----------------------------
# ------- Applications -------
# ----------------------------


# ===================================================================
# @                        Terminal Emulator                       @#
# ===================================================================


def term_emulator():
    sepertors = [  # @ Separator
        " ",  # |0> Space
        " -e ",  # |1> Execute
        " && ",  # |2> Join commands
        " & ",  # |3> Run detached
        " sudo ",  # |4> Elevated
        " --class ",  # |5> Class label
    ]

    terminals = [
        "Terminal",  # | BIN::Terminal
        "kitty",  # | Preferred
        "alacritty",  # | Alternatve
        guess_terminal(),  # | Default
    ]

    TTY.emulator = wehave(terminals)
    return TTY.emulator


# print(f"Terminal Emulator: {term_emulator()}")

# ===================================================================
# @                     Package Manager Update                     @#
# ===================================================================
# doc https://www.cyberciti.biz/faq/linux-update-all-packages-command/


def package_manager_update():
    _update_commands = {
        "~[MANAGER]~": "~[COMMAND]~",
        # > ArchLinux
        "paru": "paru",
        "yay": "yay",
        "pacman": "sudo pacman --sync --refresh --sysupgrade",
        # > Debian/Ubuntu
        "apt-get": "apt-get update && apt-get upgrade",
        # > RHEL/CentOS/Red Hat/Fedora Linux
        "yum": "yum update",
        # > OpenSUSE/Suse Linux
        "zypper": "zypper refresh && zypper update",
        # > Gentoo Linux
        "emerge": "emerge --sync && emerge --update --deep --with-bdeps=y @world",
        # > Alpine Linux
        "apk": "apk upgrade && apk update",
    }

    _manager = wehave(_update_commands)
    _update_cmd = _update_commands.get(_manager)

    TTY.reset()
    TTY.classname = "Package Manager"
    TTY.command = _update_cmd
    return TTY


# print(f"Package Manager Update: {package_manager_update()}")
# ===================================================================
# @                      System/Process Monitor                    @#
# ===================================================================


def system_monitor():
    # | Options
    sys_monitors_tty = ["btop", "btm", "ytop", "bpytop", "gotop", "htop"]
    sys_monitors_gui = ["system-monitoring-center", "stacer"]

    # | Preferred
    prefer_tty = True

    # | Default

    if prefer_tty:
        TTY.reset()
        TTY.emulator = "alacritty"
        TTY.classname = "Process Monitor"
        TTY.command = wehave(sys_monitors_tty)
        return TTY
    else:
        return wehave(sys_monitors_gui)


# print(f"System Monitor: {system_monitor()}")

# ===================================================================
# @                         Lockscreen Utility                     @#
# ===================================================================
bLock = [
    "Lockscreen",  # | BIN::Lockscreen
    "Lockscreen --update",  # | BIN::Lockscreen
    "betterlockscreen --update " + str(WALLPAPERS),  # | Update
    "betterlockscreen --lock",  # | No Effect
    "betterlockscreen --lock blur",  # | Blurred
    "betterlockscreen --lock dim",  # | Dimmed
]

screenLock = [
    bLock[0],
    bLock[1],
    "i3lock -c 000000",
    "slock",
]


def lockscreen():
    # | Options
    _lockers = {
        "i3lock": "i3lock -c 000000",
        "betterlockscreen": bLock[1],
        "slock": "slock",
    }

    _locker = wehave(_lockers)
    _locker_cmd = _lockers.get(_locker)
    return _locker_cmd


def lockscreen_update():
    _updaters = {
        "betterlockscreen": bLock[0],
    }

    _updater = wehave(_updaters)
    _updater_cmd = _updaters.get(_updater)

    TTY.reset()
    TTY.classname = "Lockscreen Wallpaper Update"
    TTY.command = _updater_cmd
    return TTY


# print(f"Screenlocker: {lockscreen()}")
# print(f"Screenlocker: {lockscreen_update()}")
lockup = 'kitty -e --class "Lockscreen Wallpaper Update" betterlockscreen --update "$WALLPAPERS"'
lockuper = lockscreen_update()
# print(lockuper)
# ===================================================================
# @                           Entertainment                        @#
# ===================================================================

play_radio = [
    "curseradio",
    "shortwave",
    "MellowPlayer",
]

play_music = [
    "yarock",
    "deadbeef",
]

play_video = [
    "mpv",
    "vlc",
]

play_youtube = [
    "freetube",
    "smtube",
    "gtk-pipe-viewer",
]

play_media = [
    play_youtube[0],
    play_radio[0],
    play_music[0],
    play_video[0],
]
media_ctl = [
    play_media[0],  # | Default player
]

# color_picker = tty_cmd + "colorpicker"
# xprop = tty_cmd + "xprop"
# xev = tty_cmd + "xv"
# nmUI = tty_cmd + "nmtui"

# >>= BACKLIGHT CONTROL =<< #

bklDown = [
    "Blight --decrease",  # @ $DOTS_BIN/utility/controller
    "brightnessctl set 10%-",
    "light -U 10",
    "sudo xbacklight -10",
]

bklUp = [
    "Blight --increase",  # @ $DOTS_BIN/utility/controller
    "brightnessctl set 10%+",
    "light -A 10",
    "sudo xbacklight +10",
    DOT_BIN / "brightness up",
]

backlight_ctl = [
    bklDown[0],  # | Down
    bklUp[0],  # | Up
]

# >>= VOLUME CONTROL =<< #
volDown = [
    "Volcono --decrease",  # @ $DOTS_BIN/utility/controller
    "pamixer --decrease 10",
    "pulseaudio-ctl down 5",
    "amixer - c 0 - q set Master 2dB -",
]

volUp = [
    "Volcono --increase",  # @ $DOTS_BIN/utility/controller
    "pamixer --increase 10",
    "pulseaudio-ctl up 5",
    "amixer - c 0 - q set Master 2dB +",
]

volMute = [
    "Volcono",  # @ $DOTS_BIN/utility/controller
    "pamixer --toggle-mute",
    "amixer set Master toggle",
]

volGUI = [
    "qjackctl",  # | Audio Server GUI
]

audio_ctl = [
    volMute[0],  # | Mute Toggle
    volDown[0],  # | Down
    volUp[0],  # | Up
    volGUI[0],  # | Mixer
    volGUI[0],  # | Server
]

# >>= LAUNCHER =<< #

dMenu = [
    "dmenu_run -i -nb '#191919' -nf '#fea63c' -sb '#fea63c' -sf '#191919' -fn 'NotoMonoRegular:bold:pixelsize=14'",
    "dmenu_run -p 'Run: '",
    DMENU_BIN / "dmconf",
    DMENU_BIN / "dmscrot",
    DMENU_BIN / "dmkill",
    DMENU_BIN / "dmlogout",
    DMENU_BIN / "dman",
    DMENU_BIN / "dmred",
    DMENU_BIN / "dmsearch",
    "passmenu",
]

Launcher = [
    # === System Default via Script =<< #
    "Launcher",  # @ $DOTS_BIN/packages/defaults
    # === jgMenu =<< #
    "jgmenu_run",
    # === Rofi =<< #
    "rofi \
        -show drun \
        -config ~/.config/qtile/resources/themes/rofi/nord.rasi \
        -display-drun 'Run: ' \
        -drun-display-format '{name}'",
    # === dMenu =<< #
    dMenu[0],
]

# >>= DEVELOPMENT =<< #

IDE = [
    "code",
    "emacsclient - c - a emacs",
    # tty_cmd + "vim",
]
VSCode = [
    IDE[0],
    # IDE[0] + DOTS,
    # IDE[0] + " " + dotfrommyfriends,
]

Emacs = [
    IDE[1],
    IDE[1] + "--eval '(ibuffer)'",
    IDE[1] + "--eval '(dired nil)'",
    IDE[1] + "--eval '(erc)'",
    IDE[1] + "--eval '(mu4e)'",
    IDE[1] + "--eval '(elfeed)'",
    IDE[1] + "--eval '(eshell)'",
    IDE[1] + "--eval '(+vterm/here nil)'",
]

Editor = [
    "nvim",
    "vim",
    "micro",
]

EditorSudo = [
    "sudo notepadqq --allow-root",
    "sudo featherpad",
]

# >>= WEB BROWSER =<< #
Browser = [
    "firefox",
    "brave-nightly",
    "vivaldi-stable",
]

# >>= Sys Management =<< #
appManager = [
    package_manager_update(),
    'kitty -e --class "Package Manager" paru',
    "kitty -e uparu",
    "pamac-manager",
    "bauh",
]
appKill = ["xkill"]
# sysViewer = [tty_cmd + "htop"]
sysManager = [
    "stacer",
    "Nm-connection-editor",
]
guiFM = [
    "doublecmd",
    "sudo doublecmd --no-splash",
    "thunar"
    # "xdg-mime query default inode/directory | sed 's/.desktop//g'"
    # 'xdg-open .'
    "pcmanfm-qt",
]
termFM = [
    "lf",
    "nnn",
    "ranger",
]
fontManager = [
    "fontmatrix --no-splash",
    "font-manager",
]

Calculator = ["speedcrunch"]
Downloader = ["qbittorrent"]
eMail = [
    "thunderbird",
    "thunderbird-nightly",
    "trojita",
]

# >>= WALLPAPER CONTROL =<< #
# Wallpaper = []

# ----------------------------
# ---------- Dates -----------
# ----------------------------


def suffix(d):
    # => Set rules for ordinal numbers in date (th, nd or st)
    return "th" if 11 <= d <= 13 else {1: "st", 2: "nd", 3: "rd"}.get(d % 10, "th")


def dateX(format, t):
    # => Generate date with ordinal numbers
    return t.strftime(format).replace("{S}", str(t.day) + suffix(t.day))


def dateNow():
    # => Date format
    return dateX("%a, {S} %b  %H:%M", dt.now())


# ----------------------------
# ------ Floating Apps -------
# ----------------------------

flClass = [
    "toolbar",
    "confirmreset",
    "makebranch",
    "maketag",
    "Arandr",
    "Conky",
    "conky",
    "ssh-askpass",
    "Lxappearance",
    "Nm-connection-editor",
    # 'SpeedCrunch',
    "BleachBit",
]

flName = [
    "nmtui",
]
