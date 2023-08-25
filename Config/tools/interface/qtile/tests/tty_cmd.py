from classes.tty_cmd import TTY_cmd
from functions.wehave import wehave

list_of_strings = [
    "cat",
    "bat",
    "bal",
    "yay",
    "paru",
]
tuple_of_strings = (
    "awks",
    "xterm",
    "kitty",
    "awk",
)
dict_of_strings = {
    "kittsy": "-class",
    "alacgritty": "--class",
    "st": "-c",
}
single_string = "pop"
strings_sep_space = "curseradio btm xterm cat"
strings_sep_comma = "btm,alacritty,kitty,st"

TTY = TTY_cmd()
TTY.classname = "System Monitor"
TTY.command = "btm"
system_monitor_tty=TTY
print(system_monitor_tty)
