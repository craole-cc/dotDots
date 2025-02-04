# doc Check whether `name` is on PATH and marked as executable.

from shutil import which
from classes.cmd_list import Command

def wehave(cmd):
    CMD = Command()
    CMD.command = cmd

    for cmd in CMD.command:
        if which(cmd):
            return cmd
            break

def wehave_location(cmd):
    CMD = Command()
    CMD.command = cmd

    for cmd in CMD.command:
        if which(cmd):
            return which(cmd)
            break
    else:
        raise ValueError(f"Verify wehave `{cmd}` installed.")
